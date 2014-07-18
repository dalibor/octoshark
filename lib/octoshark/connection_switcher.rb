module Octoshark
  class ConnectionSwitcher

    attr_reader :connection_pools

    def initialize(configs = {})
      @default_pool     = ActiveRecord::Base.connection_pool
      @connection_pools = { default: @default_pool }.with_indifferent_access

      configs.each_pair do |name, config|
        spec = ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(
          config, "#{config[:adapter]}_connection"
        )
        @connection_pools[name] = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
      end
    end

    def current_connection
      Thread.current[OCTOSHARK] || raise(NoCurrentConnectionError, "No current connection.")
    end

    def current_or_default_connection
      Thread.current[OCTOSHARK] || @default_pool.connection
    end

    def connection(name)
      Thread.current[OCTOSHARK] = find_connection_pool(name).connection
    end

    def with_connection(name, &block)
      result = nil

      find_connection_pool(name).with_connection do |connection|
        previous_connection = Thread.current[OCTOSHARK]
        Thread.current[OCTOSHARK] = connection
        begin
          result = yield(connection)
        ensure
          Thread.current[OCTOSHARK] = previous_connection
        end
      end

      result
    end

    def find_connection_pool(name, &block)
      @connection_pools[name] || raise(NoConnectionError, "No such database connection '#{name}'")
    end
  end
end
