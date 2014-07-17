module Octoshark
  class ConnectionManager

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
      Thread.current[:octoshark] || @default_pool.connection
    end

    def connection(name)
      Thread.current[:octoshark] = find_connection_pool(name).connection
    end

    def find_connection_pool(name, &block)
      connection_pool = @connection_pools[name]

      if connection_pool
        connection_pool
      else
        raise Octoshark::NoConnectionError, "No such database connection '#{name}'"
      end
    end
  end
end
