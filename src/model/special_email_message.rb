module LambdaMail
  module Model
    class SpecialEmailMessage
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime

      property :subject, Text
      property :body, Text
      property :recipient, Text
    end
  end
end
