module LambdaMail
  module Model
    class Event
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :kind, Text
      property :data, Text

      def message
        case kind
        when 'subscribe'
          "#{data} subscribed"
        when 'recipient_add'
          "#{data} was added by an admin"
        when 'unsubscribe'
          "#{data} unsubscribed"
        when 'send'
          "Message \"#{ComposedEmailMessage.get(data.to_i)&.message_subject || '<i>deleted</i>'}\" sent"
        else
          "???"
        end
      end

      def self.save_subscribe(email_address)
        create(kind: 'subscribe', data: email_address).save
      end

      def self.save_recipient_add(email_address)
        create(kind: 'recipient_add', data: email_address).save
      end

      def self.save_unsubscribe(email_address)
        create(kind: 'unsubscribe', data: email_address).save
      end

      def self.save_send(email_message)
        create(kind: 'send', data: email_message.id).save
      end
    end
  end
end