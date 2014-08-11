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
    extend ActiveSupport::Concern

    attr_accessor :connection_name

    included do
      alias_method_chain :log, :octoshark
    end

    def log_with_octoshark(sql, name = "SQL", *other_args, &block)
      if connection_name
        name = "[Octoshark: #{connection_name}] #{name}"
      end

      log_without_octoshark(sql, name, *other_args, &block)
    end
  end
end

ActiveRecord::Base.send(:include, Octoshark::ActiveRecordBase)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Octoshark::ActiveRecordAbstractAdapter)
