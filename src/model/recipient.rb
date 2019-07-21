module LambdaMail
  module Model
    class Recipient
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :name, Text
      property :email_address, Text, unique: true, required: true
    end
  end
end
