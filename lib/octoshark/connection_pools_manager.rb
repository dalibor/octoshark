module Octoshark
  class ConnectionPoolsManager
    include CurrentConnection

    # Octoshark needs to keep track of all persistent connection managers
    # in order to automatically reconnect on connection establish.
    @@connection_managers = []

    def self.connection_managers
      @@connection_managers
    end

    def self.reset_connection_managers!
      connection_managers.each(&:reset!)
    end

    def self.disconnect!
      connection_managers.map(&:disconnect!)
      @@connection_managers = []
    end

    attr_reader :connection_pools

    def initialize(configs = {})
      @configs = configs.with_indifferent_access
      setup_connection_pools

      self.class.connection_managers << self
    end

    def reset!
      disconnect!
      setup_connection_pools
    end

    def with_connection(name, database_name = nil, &block)
      connection_pool = find_connection_pool(name)

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

    def find_connection_pool(name)
      @connection_pools[name] || raise(Octoshark::Error::NoConnection, "No such database connection '#{name}'")
    end

    def disconnect!
      @connection_pools.values.each do |connection_pool|
        connection_pool.disconnect!
      end
    end

    private
    def spec_class
      if defined?(ActiveRecord::ConnectionAdapters::ConnectionSpecification)
        spec_class = ActiveRecord::ConnectionAdapters::ConnectionSpecification
      else
        # Rails 3.0, 3.1 and 3.2
        spec_class = ActiveRecord::Base::ConnectionSpecification
      end
    end

    def setup_connection_pools
      @connection_pools = HashWithIndifferentAccess.new

      @configs.each_pair do |name, config|
        @connection_pools[name] = create_connection_pool(name, config)
      end
    end

    def create_connection_pool(name, config)
      adapter_method = "#{config[:adapter]}_connection"
      spec =
        if spec_class.instance_method(:initialize).arity == 3
          # Rails 5 ConnectionSpecification accepts spec name
          spec_class.new(name, config, adapter_method)
        else
          spec_class.new(config, adapter_method)
        end

      ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
    end
  end
end
