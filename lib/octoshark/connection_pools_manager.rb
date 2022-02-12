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

    def setup_connection_pools
      @connection_pools = HashWithIndifferentAccess.new

      @configs.each_pair do |name, config|
        @connection_pools[name] = create_connection_pool(name, config)
      end
    end

    def create_connection_pool(name, config)
      spec = build_connection_pool_spec(name, config)

      ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
    end

    private

    def build_connection_pool_spec(name, config)
      if active_record_6_1_or_7?
        env_name = defined?(Rails) ? Rails.env : nil
        db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(env_name, name, config)

        pool_config_class = ActiveRecord::ConnectionAdapters::PoolConfig

        if pool_config_class.instance_method(:initialize).arity == 2
          # ActiveRecord 6.1
          pool_config_class.new(owner_name = ActiveRecord::Base, db_config)
        else
          # ActiveRecord 7.0
          pool_config_class.new(
            owner_name = ActiveRecord::Base,
            db_config,
            role = ActiveRecord::Base.current_role,
            shard = ActiveRecord::Base.current_shard
          )
        end
      else
        adapter_method = "#{config[:adapter]}_connection"

        if active_record_4_or_5_or_6?
          spec_class = ActiveRecord::ConnectionAdapters::ConnectionSpecification

          if spec_class.instance_method(:initialize).arity == 3
            # ActiveRecord 5.x and 6.0
            spec_class.new(name, config, adapter_method)
          else
            # ActiveRecord 4.x
            spec_class.new(config, adapter_method)
          end
        else
          # ActiveRecord 3.x
          ActiveRecord::Base::ConnectionSpecification.new(config, adapter_method)
        end
      end
    end

    def active_record_6_1_or_7?
      defined?(ActiveRecord::ConnectionAdapters::PoolConfig)
    end

    def active_record_4_or_5_or_6?
      defined?(ActiveRecord::ConnectionAdapters::ConnectionSpecification)
    end
  end
end
