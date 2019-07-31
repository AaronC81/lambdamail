require 'hashie'

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
        JSON.parse(sections_json || '[]').map { |x| Hashie::Mash.new(x) }
      end
    end
  end
end
