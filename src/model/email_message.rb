module LambdaMail
  module Model
    class EmailMessage
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :template_plugin, Text
      property :template_name, Text
      property :message_subject, Text
      property :status, Text, default: 'draft'
      property :recipients, Text
      has n, :email_sections

      def status_message
        {
          'draft': 'Draft',
          'sent_success': 'Sent successfully',
          'sent_failed': 'Failed to fully send',
          'recipe': 'Recipe'
        }[status] || 'Unknown status'
      end
    end
  end
end
