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

      sig { params(package: String, id: String).returns(Template) }
      def self.find(package, id)
        templates = []
        Configuration.plugins.each do |p|
          templates.push(*p.templates.map { |t| [p, t] })
        end
        template = templates.find do |(p, t)|
          t.id == id && p.package == package
        end.last
        raise 'could not find template' unless template

        template
      end

      sig { params(message: Model::ComposedEmailMessage, recipient: Model::Recipient).returns(String) }
      def render_email_message(message, recipient=nil)
        # TODO: this needs to convert each section into HTML
        engine = Haml::Engine.new(haml)
        engine.render(
          Object.new,
          sections: message.sections,
          recipient: recipient,
          unsubscribe_url: (App.base_url +
            "/unsubscribe?token=#{recipient.unsubscribe_token}" if recipient)
        )
      end
    end
  end
end
