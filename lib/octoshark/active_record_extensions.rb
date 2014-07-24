module Octoshark
  module ActiveRecordBase
    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :establish_connection, :octoshark
      end
    end

    module ClassMethods
      def establish_connection_with_octoshark(*args)
        establish_connection_without_octoshark(*args)
        Octoshark.reload! if Octoshark.configured?
      end
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

ActiveRecord::Base.send(:include, Octoshark::ActiveRecordBase)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:prepend, Octoshark::ActiveRecordAbstractAdapter)
