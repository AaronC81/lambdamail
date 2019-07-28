# typed: true
require_relative 'content/section_kind.rb'
require_relative 'content/template.rb'

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

    sig { returns(T::Array[Content::Template]) }
    attr_reader :templates

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
      @templates = []
    end

    sig do
      params(
        id: String,
        name: String,
        block: T.nilable(T.proc.params(x: Content::SectionKind).void)
      ).returns(Content::SectionKind)
    end
    def define_section_kind(id:, name:, &block)
      new_kind = Content::SectionKind.new(id: id, name: name)
      section_kinds << new_kind
      block&.call(new_kind)
      new_kind
    end

    sig do
      params(
        id: String,
        name: String,
        haml: String,
        block: T.nilable(T.proc.params(x: Content::Template).void)
      ).returns(Content::Template)
    end
    def define_template(id:, name:, haml:, &block)
      new_template = Content::Template.new(id: id, name: name, haml: haml)
      templates << new_template
      block&.call(new_template)
      new_template
    end
  end
end
