module Octoshark
  module CurrentConnection
    def current_connection
      Thread.current[identifier] || raise(Octoshark::Error::NoCurrentConnection, "No current connection")
    end

    def current_connection?
      !Thread.current[identifier].nil?
    end

    def current_or_default_connection
      Thread.current[identifier] || ActiveRecord::Base.connection_pool.connection
    end

    def without_connection(&block)
      change_connection_reference(nil) do
        yield
      end
    end

    def identifier
      @identifier ||= "octoshark_#{object_id}"
    end

    private
    def change_connection_reference(connection, &block)
      previous_connection = Thread.current[identifier]
      Thread.current[identifier] = connection

      begin
        yield
      ensure
        Thread.current[identifier] = previous_connection
      end
    end
  end
end
