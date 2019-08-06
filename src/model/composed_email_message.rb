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
          'sent_success' => 'Sent successfully',
          'sent_failed' => 'Failed to fully send',
          'recipe' => 'Recipe'
        }[status] || 'Unknown status'
      end

      def status_phrase
        {
          'draft' => 'is a draft',
          'sent_success' => 'has been sent successfully',
          'sent_failed' => 'encountered errors while sending',
          'recipe' => 'is a recipe'
        }[status] || 'Unknown status'
      end

      def sections
        JSON.parse((sections_json.nil? || sections_json == '') ? '[]' : sections_json).map { |x| Hashie::Mash.new(x) }
      end

      def send_email
        raise 'can\'t send a non-draft' if status != 'draft'
        raise 'already assigned a batch' if sidekiq_batch_id != ''

        batch = Sidekiq::Batch.new
        batch.jobs do
          # TODO: render individually, with an unsub link
          template = Content::Template.find(template_plugin_package, template_plugin_id)
          recipients_array = Model::Recipient.all.map(&:email_address)
          self.recipients = recipients_array.join(';')
          self.save!

          recipients_array.each do |recipient|
            p recipient
            body = template.render_email_message(self)
            message = Model::SpecialEmailMessage.create(
              subject: message_subject,
              recipient: recipient,
              body: body
            )
            message.save # TODO: replace save! with save elsewhere
            message.send_email
          end
        end
        self.sidekiq_batch_id = batch.bid
        self.save!
      end
    end
  end
end
