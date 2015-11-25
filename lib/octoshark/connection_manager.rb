module Octoshark
  class ConnectionManager

    attr_reader :connection_pools

    def initialize(configs = {})
      @configs = configs
      @connection_pools = ThreadSafe::Cache.new
      setup_connection_pools

      Octoshark.connection_managers << self
    end

    def reset!
      disconnect!
      setup_connection_pools
    end

    def current_connection
      Thread.current[identifier] || raise(Octoshark::Error::NoCurrentConnection, "No current connection")
    end

    def current_connection?
      !Thread.current[identifier].nil?
    end

    def current_or_default_connection
      Thread.current[identifier] || ActiveRecord::Base.connection_pool.connection
    end

    def with_connection(name, &block)
      connection_pool = find_connection_pool(name)
      with_connection_pool(name, connection_pool, &block)
    end

    def with_new_connection(name, config, reusable: false, &block)
      if reusable
        connection_pool = @connection_pools.fetch_or_store(name) { create_connection_pool(config) }
        with_connection_pool(name, connection_pool, &block)
      else
        connection_pool = create_connection_pool(config)
        with_connection_pool(name, connection_pool, &block).tap do
          connection_pool.disconnect!
        end
      end
    end

    def use_database(name, database_name, &block)
      connection_pool = find_connection_pool(name)
      with_connection_pool(name, connection_pool, database_name, &block)
    end

    def without_connection(&block)
      change_connection_reference(nil) do
        yield
      end
    end

    def find_connection_pool(name)
      @connection_pools[name] || raise(Octoshark::Error::NoConnection, "No such database connection '#{name}'")
    end

    def disconnect!
      @connection_pools.values.each do |connection_pool|
        connection_pool.disconnect!
      end
    end

    def identifier
      @identifier ||= "octoshark_#{object_id}"
    end

    private
    def spec_class
      if defined?(ActiveRecord::ConnectionAdapters::ConnectionSpecification)
        spec_class = ActiveRecord::ConnectionAdapters::ConnectionSpecification
      else
        spec_class = ActiveRecord::Base::ConnectionSpecification
      end
    end

    def change_connection_reference(connection, &block)
      previous_connection = Thread.current[identifier]
      Thread.current[identifier] = connection

      begin
        yield
      ensure
        Thread.current[identifier] = previous_connection
      end
    end

    def setup_connection_pools
      @connection_pools = ThreadSafe::Cache.new

      @configs.each_pair do |name, config|
        @connection_pools[name] = create_connection_pool(config)
      end
    end

    def create_connection_pool(config)
      config = config.with_indifferent_access
      spec = spec_class.new(config, "#{config[:adapter]}_connection")
      ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
    end

    def with_connection_pool(name, connection_pool, database_name = nil, &block)
      connection_pool.with_connection do |connection|
        connection.connection_name = name
        if database_name
          connection.database_name = database_name
          connection.execute("use #{database_name}")
        end

        change_connection_reference(connection) do
          yield(connection)
        end
      end
    end
  end
end
