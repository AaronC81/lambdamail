require 'mail'
require_relative 'utilities.rb'
require 'sidekiq'

module LambdaMail
  module Mailing
    class SendEmailWorker
      include Sidekiq::Worker
      def perform(smtp_details, imap_details, imap_sent_mailbox, email_subject, email_to, email_body, delete_from_sent=false)
        # Create a random message ID
        mail_message_id =
          "<#{Utilities.generate_token}@lambdamail.smtp>"

        # Sidekiq puts keys back to strings, we want symbols
        smtp_details = Utilities.deep_keys_to_sym(smtp_details)
        imap_details = Utilities.deep_keys_to_sym(imap_details)

        from_address = smtp_details[:address]

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
        mail_message.delivery_method :smtp, smtp_details
        mail_message.deliver

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

    class << self
      attr_accessor :smtp_details, :imap_details, :imap_sent_mailbox
    end

    def self.send_raw_email(email_subject, email_to, email_body, delete_from_sent=false)
      SendEmailWorker.perform_async(
        smtp_details,
        imap_details,
        imap_sent_mailbox,
        email_subject,
        email_to,
        email_body,
        delete_from_sent
      )
    end
  end
end