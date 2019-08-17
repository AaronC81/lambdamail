require 'hashie'
require 'sidekiq'
require 'sidekiq/batch'

module LambdaMail
  module Model
    class ComposedEmailMessage
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :template_plugin_package, Text
      property :template_plugin_id, Text
      property :message_subject, Text
      property :status, Text, default: 'draft'
      property :recipients, Text
      property :sections_json, Text
      property :sidekiq_batch_id, Text, default: ''

      def status_message
        {
          'draft' => 'Draft',
          'sending' => 'Sending',
          'sent_success' => 'Sent successfully',
          'sent_failed' => 'Failed to fully send',
          'recipe' => 'Recipe'
        }[status] || 'Unknown status'
      end

      def status_phrase
        {
          'draft' => 'is a draft',
          'sending' => 'is being sent now',
          'sent_success' => 'has been sent successfully',
          'sent_failed' => 'encountered errors while sending',
          'recipe' => 'is a recipe'
        }[status] || 'has an unknown status'
      end

      def sections
        JSON.parse((sections_json.nil? || sections_json == '') ? '[]' : sections_json).map { |x| Hashie::Mash.new(x) }
      end

      def has_subject?
        !(message_subject == '' || message_subject.nil?)
      end

      def sendable?
        status == 'draft'
      end

      def send_email
        raise 'not sendable' unless sendable?
        raise 'already assigned a batch' if sidekiq_batch_id != ''
        raise 'can\'t send an email with no subject' unless has_subject?

        batch = Sidekiq::Batch.new
        batch.jobs do
          template = Content::Template.find(template_plugin_package, template_plugin_id)
          self.recipients = Model::Recipient.all.map(&:email_address).join(';')
          self.save

          Model::Recipient.each do |recipient|
            body = template.render_email_message(self, recipient)
            message = Model::SpecialEmailMessage.create(
              subject: message_subject,
              recipient: recipient.email_address,
              body: body
            )
            message.save
            message.send_email
          end
        end
        batch.on(
          :complete,
          'LambdaMail::Model::ComposedEmailMessage::Callback#on_sidekiq_batch_complete',
          'id' => id
        )
        self.sidekiq_batch_id = batch.bid
        self.status = 'sending'
        self.save
      end

      class Callback
        def on_sidekiq_batch_complete(status, options)
          message = ComposedEmailMessage.get(options['id'])
          message.status = status.failures == 0 ? 'sent_success' : 'sent_failed'
          message.save
        end
      end
    end
  end
end
