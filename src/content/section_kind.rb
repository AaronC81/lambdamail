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

      sig { params(id: String, name: String).void }
      def initialize(id:, name:)
        @id = id
        @name = name
      end

      PROPERTY_TYPES = %i[text long_text integer number].freeze

      def define_property(name:, type:)
        raise "invalid property type #{type}" unless PROPERTY_TYPES.include?(type)
        raise "already defined property #{name}" if properties[name]

        properties[name] = type
      end
    end
  end
end
