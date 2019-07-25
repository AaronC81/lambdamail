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
          token: token
        )

        Mailing.send_raw_email(
          'Please confirm your mailing list subscription',
          email_address,
          body,
          true
        )
      end
    end
  end
end
