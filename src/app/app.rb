# typed: ignore
require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'sequel'
Sequel::Model.plugin :timestamps
require 'sinatra/sequel'
require 'sidekiq/api'

module LambdaMail
  class App < Sinatra::Application
    enable :sessions
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

    class << self
      attr_accessor :base_url
    end

    before do
      self.class.base_url ||= request.base_url
      @logs = Configuration.logs
      @sidekiq_running = (Sidekiq::ProcessSet.new.size > 0)
    end

    get '/' do
      raise 'nyi'
    end

    namespace '/subscribe' do
      get do
        render_page('subscribe/form', 'Subscribe')
      end

      get '/done' do
        render_page('subscribe/done', 'Confirm Subscription')
      end

      post do
        # TODO: an "only" assertion method might be nice
        # TODO: check user isn't already on the mailing list
        pending_subscription = Model::PendingSubscription.first(email_address: params[:email_address])
        if pending_subscription.nil?
          pending_subscription = Model::PendingSubscription.create(
            email_address: params[:email_address],
            name: params[:name],
            token: Utilities.generate_token
          )
          pending_subscription.save!
        else
          # The user could have entered a different name since their first subscription
          pending_subscription.name = params[:name]
          pending_subscription.save!
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
          name: name
        )
        recipient.save!

        render_page('subscribe/confirm', 'Subscription Confirmed')
      end
    end

    namespace '/admin' do
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
          @message.save!
          flash[:success] = 'New email message created.'
          redirect to "#{request.path_info}/#{@message.id}"
        end

        get '/:id' do |id|
          @message = Model::ComposedEmailMessage.get(id)
          @plugins = Configuration.plugins
          @render_url = "/admin/messages/#{id}/render"
          @presend_url = "/admin/messages/#{id}/presend"
          render_admin_page('messages/show', 'Message')
        end

        put '/:id' do |id|
          @message = Model::ComposedEmailMessage.get(id)
          write_params_into_model(params, @message)
          @message.save!
          flash[:success] = 'Email message updated.'
          redirect back
        end

        get '/:id/render' do |id|
          message = Model::ComposedEmailMessage.get(id)
          templates = []
          Configuration.plugins.each do |p|
            templates.push(*p.templates.map { |t| [p, t] })
          end
          template = templates.find do |(p, t)|
            t.id == message.template_plugin_id && p.package == message.template_plugin_package
          end.last
          raise 'could not find template' unless template

          template.render_email_message(message)
        end

        get '/:id/presend' do |id|
          @message = Model::ComposedEmailMessage.get(id)
          @recipients = Model::Recipient.all
          @render_url = "/admin/messages/#{id}/render"

          render_admin_page('messages/presend', 'Ready to send')
        end

        post '/:id/send' do |id|
          @message = Model::ComposedEmailMessage.get(id)
          @message.send_email
          redirect to "#{request.path_info}/../sent"
        end
      end

      namespace '/recipients' do
        get do
          @recipients = Model::Recipient.all
          render_admin_page('recipients/list', 'Recipients')
        end

        post do
          @recipient = Model::Recipient.create
          write_params_into_model(params, @recipient)
          @recipient.save!
          flash[:success] = 'New recipient created.'
          redirect back
        end

        delete '/:id' do |id|
          @recipient = Model::Recipient.get(id)
          @recipient.destroy
          flash[:success] = 'Recipient deleted.'
          redirect back
        end
      end
    end
  end
end
