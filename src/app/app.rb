# typed: ignore
require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'sequel'
Sequel::Model.plugin :timestamps
require 'sinatra/sequel'
require 'sidekiq/api'
require 'action_view'
require 'digest'

include ActionView::Helpers::DateHelper

module LambdaMail
  class App < Sinatra::Application
    enable :sessions
    disable :show_exceptions
    register Sinatra::Flash

    def render_admin_page(name, title, **locals)
      @title = title
      @name = name
      haml name.to_sym, layout: :admin_page, locals: locals
    end

    def render_page(name, title, **locals)
      @title = title
      @name = name
      haml name.to_sym, layout: :page, locals: locals
    end

    def write_params_into_model(params, model)
      params.reject { |k, _| k.start_with?('_') }.each do |k, v|
        raise "unexpected parameter #{k} specified" \
          unless model.class.properties.any? { |p| p.name.to_s == k }

        model.send("#{k}=", v)
      end
    end

    def auth!
      unless session[:authenticated] || defined?(RSpec)
        flash[:error] = 'You need to log in to access this page.'
        redirect to '/admin/login'
      end
    end

    class << self
      attr_accessor :base_url
    end

    before do
      self.class.base_url ||= request.base_url
      @logs = Configuration.logs
      @sidekiq_running = (Sidekiq::ProcessSet.new.size > 0)
    end

    get '/' do
      redirect to '/subscribe'
    end

    namespace '/subscribe' do
      get do
        render_page('subscribe/form', 'Subscribe')
      end

      get '/done' do
        render_page('subscribe/done', 'Confirm Subscription')
      end

      post do
        if Model::Recipient.all.find { |r| r.email_address == params[:email_address] }
          # This user is already subscribed, so silently do nothing.
          # We don't want to leak who is subscribed by giving a "You're already subscribed" message.
          redirect to "#{request.path_info}/done"
        end

        pending_subscription = Model::PendingSubscription.first(email_address: params[:email_address])
        if pending_subscription.nil?
          pending_subscription = Model::PendingSubscription.create(
            email_address: params[:email_address],
            name: params[:name],
            token: Utilities.generate_token
          )
          pending_subscription.save
        else
          # The user could have entered a different name since their first subscription
          pending_subscription.name = params[:name]
          pending_subscription.save
        end
        pending_subscription.send_confirmation_email

        redirect to "#{request.path_info}/done"
      end

      get '/confirm' do
        email_address = params[:email_address]
        token = params[:token]
        halt 422, 'email_address or token not specified' unless email_address && token

        pending_subscription = Model::PendingSubscription.first(email_address: params[:email_address])

        halt 403, 'this email_address does not have a pending subscription' unless pending_subscription
        halt 403, 'incorrect token' if pending_subscription.token != token

        name = pending_subscription.name
        email_address = pending_subscription.email_address
        pending_subscription.destroy

        recipient = Model::Recipient.new(
          email_address: email_address,
          name: name,
          salt: Utilities.generate_token
        )
        recipient.save

        Model::Event.save_subscribe(recipient.email_address)

        render_page('subscribe/confirm', 'Subscription Confirmed')
      end
    end

    namespace '/unsubscribe' do
      get do
        @token = params[:token]
        halt 422, 'token not specified' unless @token

        @recipient = Model::Recipient.all.find { |r| r.unsubscribe_token == @token }
        halt 403, 'no recipient with this token' unless @recipient

        render_page('unsubscribe/confirm', 'Unsubscribe')
      end

      post do
        token = params[:token]
        halt 422, 'token not specified' unless token

        recipient = Model::Recipient.all.find { |r| r.unsubscribe_token == token }
        recipient.destroy

        Model::Event.save_unsubscribe(recipient.email_address)

        redirect to "#{request.path_info}/done"
      end

      get '/done' do
        render_page('unsubscribe/done', 'Unsubscribe Complete')
      end
    end

    namespace '/admin' do
      before do
        auth! unless request.path_info == '/admin/login'
      end

      error DataMapper::ObjectNotFoundError do
        status 404
        @status = 404
        render_admin_page('error', 'Item not found')
      end

      not_found do
        status 404
        @status = 404
        render_admin_page('error', 'Item not found')
      end

      error Exception do
        status 500
        @status = 500
        render_admin_page('error', 'Server error')
      end

      namespace '/login' do
        get do
          render_page('login', 'Login')
        end

        post do
          unless File.file?(Configuration.password_file)
            flash[:error] = "There is no password file. Please create #{Configuration.password_file}, containing a SHA256 hash of a chosen password."
            redirect back
          end

          if File.read(Configuration.password_file).chomp == Digest::SHA256.hexdigest(params[:password])
            session[:authenticated] = true
            redirect to '/admin/dashboard'
          else
            flash[:error] = "Incorrect password."
            redirect back
          end
        end
      end

      get '/dashboard' do
        @events = Model::Event.all
        render_admin_page('dashboard', 'Dashboard')
      end

      namespace '/messages' do
        get do
          @messages = Model::ComposedEmailMessage.all
          render_admin_page('messages/list', 'Messages')
        end

        get '/special' do
          @special_messages = Model::SpecialEmailMessage.all
          render_admin_page('messages/special', 'Special Messages')
        end

        post do
          @message = Model::ComposedEmailMessage.create
          write_params_into_model(params, @message)
          @message.save
          flash[:success] = 'New email message created.'
          redirect to "#{request.path_info}/#{@message.id}"
        end

        get '/:id' do |id|
          @message = Model::ComposedEmailMessage.get!(id)
          @plugins = Configuration.plugins
          @render_url = "/admin/messages/#{id}/render"
          @presend_url = "/admin/messages/#{id}/presend"
          render_admin_page('messages/show', 'Message')
        end

        put '/:id' do |id|
          @message = Model::ComposedEmailMessage.get!(id)
          write_params_into_model(params, @message)
          @message.save
          flash[:success] = 'Email message updated.'
          redirect back
        end

        delete '/:id' do |id|
          @message = Model::ComposedEmailMessage.get!(id)
          @message.destroy
          flash[:success] = 'Email message deleted.'
          redirect back
        end

        get '/:id/render' do |id|
          message = Model::ComposedEmailMessage.get!(id)

          next "Please select a template" unless \
            message.template_plugin_id && message.template_plugin_package &&
            message.template_plugin_id != '' &&
            message.template_plugin_package != ''

          template = Configuration.find_template(
            message.template_plugin_package,
            message.template_plugin_id
          )

          template.render_email_message(message)
        end

        get '/:id/presend' do |id|
          @message = Model::ComposedEmailMessage.get!(id)
          @recipients = Model::Recipient.all
          @render_url = "/admin/messages/#{id}/render"

          render_admin_page('messages/presend', 'Ready to send')
        end

        post '/:id/send' do |id|
          @message = Model::ComposedEmailMessage.get!(id)
          @message.send_email

          Model::Event.save_send(@message)

          redirect to "#{request.path_info}/../sent"
        end

        get '/:id/sent' do |id|
          render_admin_page('messages/sent', 'Sent')
        end
      end

      namespace '/recipients' do
        get do
          @recipients = Model::Recipient.all
          render_admin_page('recipients/list', 'Recipients')
        end

        post do
          @recipient = Model::Recipient.create(salt: Utilities.generate_token)
          write_params_into_model(params, @recipient)
          @recipient.save
          flash[:success] = 'New recipient created.'
          Model::Event.save_recipient_add(@recipient.email_address)
          redirect back
        end

        get '/many' do
          render_admin_page('recipients/many', 'Add Many Recipients')
        end

        post '/many' do
          recipients = params[:recipients]
          count = 0
          recipients.split("\n").each do |email|
            next if email.chomp == ''
            recipient = Model::Recipient.create(
              email_address: email,
              salt: Utilities.generate_token
            )
            recipient.save
            Model::Event.save_recipient_add(recipient.email_address)
            count += 1
          end
          flash[:success] = "Added #{count} recipients."
          redirect to '/admin/recipients'
        end

        delete '/:id' do |id|
          @recipient = Model::Recipient.get!(id)
          @recipient.destroy
          flash[:success] = 'Recipient deleted.'
          redirect back
        end
      end

      namespace '/settings' do
        get do
          @config = Configuration
          @versions = {
            'LambdaMail' => LambdaMail::VERSION,
            'Ruby' => RUBY_VERSION,
            'Sidekiq' => Sidekiq::VERSION,
            'DataMapper' => DataMapper::VERSION,
            'SQLite' => `sqlite3 --version`,
          }
          render_admin_page('settings/index', 'Settings')
        end

        get '/dump' do
          content_type 'text/plain'
          `sqlite3 #{Configuration.database_file} .dump`
        end
      end
    end
  end
end
