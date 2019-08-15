require 'digest'

module LambdaMail
  module Model
    class Recipient
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :name, Text
      property :email_address, Text, unique: true, required: true
      property :salt, Text

      def unsubscribe_token
        Digest::SHA256.hexdigest(name + email_address + salt)
      end
    end
  end
end
