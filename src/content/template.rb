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

      sig { params(message: Model::ComposedEmailMessage, recipient: Model::Recipient).returns(String) }
      def render_email_message(message, recipient=nil)
        # TODO: this needs to convert each section into HTML
        engine = Haml::Engine.new(haml)
        rendered_sections = message.sections.map do |section|
          section_kind = Configuration.find_section_kind(
            section.plugin_package,
            section.plugin_id
          )

          Hashie::Mash.new(
            title: section.title,
            html: section_kind.render(section.properties)
          )
        end
        engine.render(
          Object.new,
          sections: rendered_sections,
          recipient: recipient,
          unsubscribe_url: (App.base_url +
            "/unsubscribe?token=#{recipient.unsubscribe_token}" if recipient)
        )
      end
    end
  end
end
