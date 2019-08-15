require 'mail'
require 'sidekiq'

module LambdaMail
  module Mailing
    class SendSpecialEmailMessageWorker
      include Sidekiq::Worker
      sidekiq_options retry: 0
      def perform(special_email_message_id, delete_from_sent)
        # Create a random message ID
        mail_message_id =
          "<#{Utilities.generate_token}@lambdamail.smtp>"

        # Load the configuration
        config = Utilities.deep_keys_to_sym(LambdaMail::Configuration.load_configuration_file)
        smtp_details = config[:mailing_list][:emailer_account][:smtp_details]
        imap_details = config[:mailing_list][:emailer_account][:imap_details]
        imap_sent_mailbox = config[:mailing_list][:emailer_account][:imap_sent_mailbox]
        from_address = smtp_details[:address]

        # Load the special email message and unpack its properties
        special_email_message = Model::SpecialEmailMessage.get(special_email_message_id)

        unless special_email_message.sent
          email_to = special_email_message.recipient
          email_subject = special_email_message.subject
          email_body = special_email_message.body

          # Create the message
          mail_message = Mail::Message.new do
            from from_address
            to email_to
            subject email_subject
            message_id mail_message_id
            body email_body
          end
          mail_message.content_type = 'text/html'

          # Send with the SMTP account
          if defined?(Sidekiq::Testing) && Sidekiq::Testing.enabled?
            mail_message.delivery_method :test
          else
            mail_message.delivery_method :smtp, smtp_details
          end
          mail_message.deliver

          # Set the sent flag
          special_email_message.sent = true
          special_email_message.save
        end

        # TODO: testing would be good, but I don't know how
        return if defined?(Sidekiq::Testing) && Sidekiq::Testing.enabled?

        # If we weren't asked to also delete the message, we can stop here
        return unless delete_from_sent

        # Open the IMAP account
        imap_account = Mail::IMAP.new(imap_details)

        # Perform a dry run of the find-and-delete to check we'll only touch one
        # message
        # Find the email with the message ID we sent earlier in the sentbox
        search_term = "HEADER Message-Id #{mail_message_id}"
        sent_message = imap_account.find(mailbox: imap_sent_mailbox,
          keys: search_term, count: 1)

        raise 'couldn\'t find email just sent' if sent_message.nil?

        # Do the deletion
        imap_account.find_and_delete(mailbox: imap_sent_mailbox,
          keys: search_term, count: 1)
      end
    end
  end
end
