# typed: true
require 'sorbet-runtime'

module LambdaMail
  module Content
    class Template
      extend T::Sig

      sig { returns(String) }
      attr_reader :id

      sig { returns(String) }
      attr_reader :name

      sig { returns(String) }
      attr_reader :haml

      sig { params(id: String, name: String, haml: String).void }
      def initialize(id:, name:, haml:)
        @id = id
        @name = name
        @haml = haml
      end

      sig { params(message: Model::ComposedEmailMessage).returns(String) }
      def render_email_message(message)
        # TODO: this needs to convert each section into HTML
        engine = Haml::Engine.new(haml)
        engine.render(
          Object.new,
          sections: message.sections
        )
      end
    end
  end
end
