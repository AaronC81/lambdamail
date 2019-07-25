module LambdaMail
  module Utilities
    def self.generate_token
      20.times.map { (('A'..'Z').to_a + ('a'..'z').to_a).sample }.join
    end

    def self.deep_keys_to_sym(obj)
      case obj
      when Hash
        obj.map { |k, v| [k.to_sym, deep_keys_to_sym(v)] }.to_h
      when Array
        obj.map { |x| deep_keys_to_sym(x) }
      else
        obj
      end
    end
  end
end