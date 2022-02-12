module Octoshark
  module ConnectionHandler
    def establish_connection(*args, **kwargs)
      Octoshark::ConnectionPoolsManager.reset_connection_managers!
      super(*args, **kwargs)
    end
  end

  module ActiveRecordAbstractAdapter
    attr_accessor :connection_name, :database_name

    def log(sql, name = "SQL", *other_args, &block)
      if connection_name || database_name
        name = "[Octoshark: #{[connection_name, database_name].compact.join(' ')}] #{name}"
      end

      super(sql, name, *other_args, &block)
    end
  end
end

if defined?(ActiveRecord::ConnectionAdapters::ConnectionHandler)
  # Rails 3.2, 4.0, 4.1, 4.2, 5.0
  ActiveRecord::ConnectionAdapters::ConnectionHandler.send(:prepend, Octoshark::ConnectionHandler)
else
  # Rails 3.0 and 3.1 does not lazy load
  require 'active_record/connection_adapters/abstract_adapter'
  ActiveRecord::ConnectionAdapters::ConnectionHandler.send(:prepend, Octoshark::ConnectionHandler)
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:prepend, Octoshark::ActiveRecordAbstractAdapter)
