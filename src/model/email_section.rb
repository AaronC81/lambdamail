module LambdaMail
  module Model
    class EmailSection
      include DataMapper::Resource
      property :id, Serial
      property :created_at, DateTime
      property :updated_at, DateTime
      
      property :title, Text
      property :plugin_package, Text
      property :plugin_id, Text
      has n, :email_section_properties
    end
  end
end
