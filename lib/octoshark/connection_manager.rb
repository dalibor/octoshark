module Octoshark
  class ConnectionManager
    include CurrentConnection

    def with_connection(config, connection_name: nil, &block)
      connection =
        if ActiveRecord::ConnectionAdapters.respond_to?(:resolve)
          # Rails 7.2+
          ActiveRecord::ConnectionAdapters.resolve(config[:adapter]).new(config)
        else
          connection_method = "#{config[:adapter]}_connection"
          ActiveRecord::Base.send(connection_method, config)
        end

      connection.connection_name = connection_name
      connection.database_name = config[:database] if config[:database]

      begin
        change_connection_reference(connection) do
          yield(connection)
        end
      ensure
        connection.disconnect!
      end
    end
  end
end
