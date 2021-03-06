# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/mongo_mapper/all/mongo_mapper.rbi
#
# mongo_mapper-0.14.0
module MongoMapper
  extend MongoMapper::Connection
end
module MongoMapper::Plugins
  def included(base = nil); end
  def plugin(mod); end
  def plugins; end
  include ActiveSupport::DescendantsTracker
end
module MongoMapper::Plugins::Associations
  def associations; end
  def build_proxy(association); end
  def embedded_associations; end
  def get_proxy(association); end
  def save_to_collection(options = nil); end
  extend ActiveSupport::Concern
end
module MongoMapper::Plugins::Associations::ClassMethods
  def associations; end
  def associations=(hash); end
  def associations_module; end
  def associations_module_defined?; end
  def belongs_to(association_id, options = nil, &extension); end
  def create_association(association); end
  def embedded_associations; end
  def inherited(subclass); end
  def many(association_id, options = nil, &extension); end
  def one(association_id, options = nil, &extension); end
end
module MongoMapper::Connection
  def config; end
  def config=(hash); end
  def config_for_environment(environment); end
  def connect(environment, options = nil); end
  def connection; end
  def connection=(new_connection); end
  def connection?; end
  def database; end
  def database=(name); end
  def handle_passenger_forking; end
  def logger; end
  def setup(config, environment, options = nil); end
end
module Kernel
end
module MongoMapper::Extensions
end
module MongoMapper::Extensions::Object
  def _mongo_mapper_deep_copy_; end
  def to_mongo; end
  extend ActiveSupport::Concern
end
module MongoMapper::Extensions::Object::ClassMethods
  def from_mongo(value); end
  def to_mongo(value); end
end
class Object < BasicObject
  extend MongoMapper::Extensions::Object::ClassMethods
  include MongoMapper::Extensions::Object
end
module MongoMapper::Extensions::Array
  def _mongo_mapper_deep_copy_; end
  extend ActiveSupport::Concern
end
module MongoMapper::Extensions::Array::ClassMethods
  def from_mongo(value); end
  def to_mongo(value); end
end
class Array
  extend MongoMapper::Extensions::Array::ClassMethods
  include MongoMapper::Extensions::Array
end
module MongoMapper::Extensions::Date
  def from_mongo(value); end
  def to_mongo(value); end
end
class Date
  extend MongoMapper::Extensions::Date
end
module MongoMapper::Extensions::ObjectId
  def from_mongo(value); end
  def to_mongo(value); end
end
class ObjectId
  extend MongoMapper::Extensions::ObjectId
end
class BSON::ObjectId
  def original_to_json(*a); end
  def to_str; end
end
module MongoMapper::Extensions::Binary
  def from_mongo(value); end
  def to_mongo(value); end
end
class Binary
  extend MongoMapper::Extensions::Binary
end
module MongoMapper::Extensions::Float
  def to_mongo(value); end
end
class Float < Numeric
  extend MongoMapper::Extensions::Float
end
module MongoMapper::Extensions::NilClass
  def from_mongo(value); end
  def to_mongo(value); end
end
class NilClass
  include MongoMapper::Extensions::NilClass
end
module MongoMapper::Extensions::Boolean
  def from_mongo(value); end
  def to_mongo(value); end
end
class Boolean
  extend MongoMapper::Extensions::Boolean
end
module MongoMapper::Extensions::Symbol
  def from_mongo(value); end
  def to_mongo(value); end
end
class Symbol
  extend MongoMapper::Extensions::Symbol
end
module MongoMapper::Extensions::Set
  def from_mongo(value); end
  def to_mongo(value); end
end
class Set
  extend MongoMapper::Extensions::Set
end
module MongoMapper::Extensions::Integer
  def from_mongo(value); end
  def to_mongo(value); end
end
class Integer < Numeric
  extend MongoMapper::Extensions::Integer
end
module MongoMapper::Extensions::String
  def _mongo_mapper_deep_copy_; end
  extend ActiveSupport::Concern
end
module MongoMapper::Extensions::String::ClassMethods
  def from_mongo(value); end
  def to_mongo(value); end
end
class String
  extend MongoMapper::Extensions::String::ClassMethods
  include MongoMapper::Extensions::String
end
module MongoMapper::Extensions::Time
  def from_mongo(value); end
  def to_mongo(value); end
end
class Time
  extend MongoMapper::Extensions::Time
end
module MongoMapper::Extensions::Hash
  def _mongo_mapper_deep_copy_; end
  extend ActiveSupport::Concern
end
module MongoMapper::Extensions::Hash::ClassMethods
  def from_mongo(value); end
end
class Hash
  extend MongoMapper::Extensions::Hash::ClassMethods
  include MongoMapper::Extensions::Hash
end
class MongoMapper::Plugins::Associations::Proxy
  def as_json(*options); end
  def association; end
  def blank?; end
  def collection(*args, &block); end
  def find_target; end
  def flatten_deeper(array); end
  def initialize(owner, association); end
  def inspect; end
  def klass(*args, &block); end
  def load_target; end
  def loaded; end
  def loaded?; end
  def method_missing(method, *args, &block); end
  def nil?; end
  def options(*args, &block); end
  def present?; end
  def proxy_association; end
  def proxy_extend(mod, *args); end
  def proxy_owner; end
  def proxy_respond_to?(*arg0); end
  def proxy_target; end
  def reload; end
  def replace(v); end
  def reset; end
  def respond_to?(*args); end
  def send(method, *args, &block); end
  def target; end
  def to_json(*options); end
  extend Forwardable
end
module MongoMapper::Middleware
end
