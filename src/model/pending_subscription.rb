require 'haml'
require 'cgi'

module LambdaMail
  module Model
    class PendingSubscription
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :email_address, Text, unique: true, key: true
      property :name, Text
      property :token, Text

      def send_confirmation_email
        # TODO: Allow name to be specified
        engine = Haml::Engine.new(
          File.read(
            File.join(
              File.dirname(__FILE__),
              '../core_emails/confirm_subscription.haml'
            )
          )
        )
        body = engine.render(
          Object.new,
          email_address: CGI.escape(email_address),
          token: token,
          base_url: App.base_url
        )

        message = Model::SpecialEmailMessage.create(
          subject: 'Please confirm your mailing list subscription',
          recipient: email_address,
          body: body
        )
        message.save!
        message.send_email
      end
    end
  end
end
