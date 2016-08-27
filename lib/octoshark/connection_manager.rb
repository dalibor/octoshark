module Octoshark
  class ConnectionManager
    include CurrentConnection

    def with_connection(config, connection_name: nil, &block)
      connection_method = "#{config[:adapter]}_connection"

      connection = ActiveRecord::Base.send(connection_method, config)
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
