module Octoshark
  module ConnectionHandler
    # def establish_connection(owner, spec)                        # Rails 3.x
    # def establish_connection(config_or_env = nil)                # Rails 4.x - 6.1
    # def establish_connection(config, owner_name:, role:, shard:) # Rails 6.2+
    def establish_connection(*args, **kwargs)
      Octoshark::ConnectionPoolsManager.reset_connection_managers!

      if kwargs.empty?
        # For backward compatibility with older versions of Rails on Ruby 3
        # that separates positional (args) and keyword arguments (kwargs).
        super(*args)
      else
        super(*args, **kwargs)
      end
    end
  end

  module ConnectionHandlerRails3
    def establish_connection(*args)
      Octoshark::ConnectionPoolsManager.reset_connection_managers!
      super(*args)
    end
  end

  module ActiveRecordAbstractAdapter
    attr_accessor :connection_name, :database_name

    def log(sql, name = "SQL", *other_args, **kwargs, &block)
      if connection_name || database_name
        name = "[Octoshark: #{[connection_name, database_name].compact.join(' ')}] #{name}"
      end

      super(sql, name, *other_args, **kwargs, &block)
    end
  end
end

# Rails 3.0 and 3.1 does not lazy load
unless defined?(ActiveRecord::ConnectionAdapters::ConnectionHandler)
  require 'active_record/connection_adapters/abstract_adapter'
end

ActiveRecord::ConnectionAdapters::ConnectionHandler.send(:prepend, Octoshark::ConnectionHandler)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:prepend, Octoshark::ActiveRecordAbstractAdapter)
