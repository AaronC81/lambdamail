require 'sorbet-runtime'
require 'redcarpet'

module LambdaMail
  module Content
    class SectionKind
      extend T::Sig

      sig { returns(String) }
      attr_reader :id

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Hash[String, Symbol]) }
      attr_reader :properties

      sig { returns(T.nilable(T.proc.params(property_values: T::Hash[String, String]).returns(String))) }
      attr_reader :renderer

      sig { params(id: String, name: String).void }
      def initialize(id:, name:)
        @id = id
        @name = name
        @properties = {}
      end

      PROPERTY_TYPES = %i[text long_text integer number].freeze

      def define_property(name:, type:)
        raise "invalid property type #{type}" unless PROPERTY_TYPES.include?(type)
        raise "already defined property #{name}" if properties[name]

        properties[name] = type
      end

      def to_render(&block)
        @renderer = block
      end

      def render(properties)
        raise "#{id} (#{name}) is missing a renderer" unless renderer
        renderer.call(Hashie::Mash.new(properties))
      end

      sig { params(md: String).returns(String) }
      def markdown(md)
        Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(md)
      end
    end
  end
end
