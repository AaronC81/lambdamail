# typed: true
require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'sequel'
Sequel::Model.plugin :timestamps
require 'sinatra/sequel'

module LambdaMail
  class App < Sinatra::Application
    enable :sessions
    register Sinatra::Flash

    def render_admin_page(name, title, **locals)
      @title = title
      haml name.to_sym, layout: :admin_page, locals: locals
    end

    def write_params_into_model(params, model)
      params.reject { |k, _| k.start_with?('_') }.each do |k, v|
        raise "unexpected parameter #{k} specified" \
          unless model.class.properties.any? { |p| p.name.to_s == k }

        model.send("#{k}=", v)
      end
    end

    get '/' do
      raise 'nyi'
    end

    namespace '/admin' do
      namespace '/messages' do
        get do
          @messages = Model::EmailMessage.all
          render_admin_page('messages/list', 'Messages')
        end

        post do
          @message = Model::EmailMessage.create
          write_params_into_model(params, @message)
          @message.save!
          flash[:success] = 'New email message created.'
          redirect to "#{request.path_info}/#{@message.id}"
        end

        get '/:id' do |id|
          @message = Model::EmailMessage.get(id)
          render_admin_page('messages/show', 'Message')
        end

        put '/:id' do |id|
          @message = Model::EmailMessage.get(id)
          write_params_into_model(params, @message)
          @message.save!
          flash[:success] = 'Email message updated.'
          redirect back
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
