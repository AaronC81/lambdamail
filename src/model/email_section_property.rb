module LambdaMail
  module Model
    class EmailSectionProperty
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime
      
      property :property_key, Text
      property :property_value, Text
    end
  end
end
