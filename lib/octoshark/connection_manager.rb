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
  end
end
