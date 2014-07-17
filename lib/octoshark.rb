require "octoshark/version"
require 'active_record'

module Octoshark
  autoload :ConnectionSwitcher, 'octoshark/connection_switcher'

  class NotConfiguredError < RuntimeError; end
  class NoConnectionError < StandardError; end;
  class NoCurrentConnectionError < StandardError; end;

  OCTOSHARK = :octoshark

  class << self
    delegate :current_connection, :with_connection, :connection,
      :connection_pools, :find_connection_pool, to: :switcher
  end

  def self.setup(configs)
    @switcher = ConnectionSwitcher.new(configs)
  end

  def self.reset!
    @switcher = nil
    Thread.current[OCTOSHARK] = nil
  end

  def self.switcher
    if @switcher
      @switcher
    else
      raise NotConfiguredError, "Octoshark is not setup. Setup connections with Octoshark.setup(configs)"
    end
  end
end
