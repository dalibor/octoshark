require "octoshark/version"
require 'active_record'

module Octoshark
  autoload :ConnectionManager, 'octoshark/connection_manager'

  def self.setup(configs)
    @connection_manager = ConnectionManager.new(configs)
  end

  def self.reset!
    @connection_manager = nil
  end

  def self.connection_manager
    @connection_manager
  end
end
