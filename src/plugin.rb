# typed: true
require_relative 'content/section_kind'

module LambdaMail
  class Plugin
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { returns(String) }
    attr_reader :package

    sig { returns(String) }
    attr_reader :description

    sig { returns(String) }
    attr_reader :version

    sig { returns(String) }
    attr_reader :path

    sig { returns(T::Array[Content::SectionKind]) }
    attr_reader :section_kinds

    sig do
      params(
        path: String,
        name: String,
        package: String,
        description: String,
        version: String
      ).void
    end
    def initialize(path:, name:, package:, description:, version:)
      @path = path
      @name = name
      @package = package
      @description = description
      @version = version
      @section_kinds = []
    end

    sig do
      params(
        id: String,
        name: String,
        block: T.proc.params(x: Content::SectionKind).void
      ).returns(Content::SectionKind)
    end
    def define_section_kind(id:, name:, &block)
      new_kind = Content::SectionKind.new(id: id, name: name)
      section_kinds << new_kind
      block.call(new_kind)
      new_kind
    end
  end
end
