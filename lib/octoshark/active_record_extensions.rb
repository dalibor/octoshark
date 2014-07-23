module AliasMethodChainResilient
  # Give us a module which will intercept attempts to alias methods named in
  # the keys of method_aliases, and instead alias the methods named in the
  # values of method_aliases.
  def self.alias_intercepting_module(method_aliases)
    Module.new do
      define_method :alias_method do |new_name, old_name|
        if method_aliases.key?(old_name.to_sym)
          super new_name, method_aliases[old_name.to_sym]
        else
          super new_name, old_name
        end
      end
    end
  end

  def prepend_features(base)
    method_aliases = instance_methods.each_with_object({}) do |method_name, aliases|
      aliases[method_name] = :"__#{method_name}_before_#{self.name}"
      base.send :alias_method, aliases[method_name], method_name
    end

    base.singleton_class.send :prepend, AliasMethodChainResilient.alias_intercepting_module(method_aliases)
    super
  end
end

module Octoshark
  module EstablishConnectionWithOctosharkReloading
    extend AliasMethodChainResilient

    def establish_connection(*)
      super
      Octoshark.reload! if Octoshark.configured?
    end
  end

  module ActiveRecordAbstractAdapter
    attr_accessor :connection_name

    def log(sql, name = "SQL", *other_args)
      if connection_name
        name = "[Octoshark: #{connection_name}] #{name}"
      end

      super(sql, name, *other_args)
    end
  end
end

ActiveRecord::Base.singleton_class.send(:prepend, Octoshark::EstablishConnectionWithOctosharkReloading)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:prepend, Octoshark::ActiveRecordAbstractAdapter)
