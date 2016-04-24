require 'octoshark/version'
require 'active_record'
require 'thread_safe'
require 'octoshark/active_record_extensions'

module Octoshark
  autoload :ConnectionManager, 'octoshark/connection_manager'
  autoload :Error,             'octoshark/error'

  # Octoshark needs to keep track of all connection managers in order to
  # automatically reconnect on connection establish.
  @@connection_managers = ThreadSafe::Array.new

  def self.connection_managers
    @@connection_managers
  end

  def self.reset_connection_managers!
    connection_managers.map(&:reset!)
  end

  def self.disconnect!
    connection_managers.map(&:disconnect!)
    @@connection_managers = []
  end
end
