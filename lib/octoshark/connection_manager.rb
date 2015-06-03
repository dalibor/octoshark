module Octoshark
  class ConnectionManager

    attr_reader :connection_pools

    def initialize(configs = {})
      configs           = configs.with_indifferent_access
      @default_pool     = ActiveRecord::Base.connection_pool
      @connection_pools = { default: @default_pool }.with_indifferent_access

      configs.each_pair do |name, config|
        spec = spec_class.new(config, "#{config[:adapter]}_connection")
        @connection_pools[name] = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
      end
    end

    def current_connection
      Thread.current[identifier] || raise(Octoshark::Error::NoCurrentConnection, "No current connection, use Octoshark.with_connection")
    end

    def current_connection?
      !Thread.current[identifier].nil?
    end

    def current_or_default_connection
      Thread.current[identifier] || @default_pool.connection
    end

    def with_connection(name, &block)
      find_connection_pool(name).with_connection do |connection|
        connection.connection_name = name

        change_connection_reference(connection) do
          yield(connection)
        end
      end
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

    private
    def spec_class
      if defined?(ActiveRecord::ConnectionAdapters::ConnectionSpecification)
        spec_class = ActiveRecord::ConnectionAdapters::ConnectionSpecification
      else
        spec_class = ActiveRecord::Base::ConnectionSpecification
      end
    end

    def change_connection_reference(connection)
      previous_connection = Thread.current[identifier]
      Thread.current[identifier] = connection

      begin
        yield
      ensure
        Thread.current[identifier] = previous_connection
      end
    end

    def identifier
      "octoshark_#{Process.pid}"
    end
  end
end
