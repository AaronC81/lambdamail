module LambdaMail
  module Model
    class EmailSection
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime
      
      property :plugin_name, Text
      property :section_name, Text
      has n, :email_section_properties
    end
  end
end
