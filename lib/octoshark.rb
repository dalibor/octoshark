require 'octoshark/version'
require 'active_record'

module Octoshark
  autoload :ConnectionSwitcher, 'octoshark/connection_switcher'

  class NotConfiguredError < RuntimeError; end
  class NoConnectionError < StandardError; end;
  class NoCurrentConnectionError < StandardError; end;

  OCTOSHARK = :octoshark

  class << self
    delegate :current_connection, :with_connection,
      :connection, :current_or_default_connection,
      :connection_pools, :find_connection_pool,
      :disconnect!, to: :switcher

    def setup(configs)
      @configs = configs
      @switcher = ConnectionSwitcher.new(configs)
    end

    def reset!
      disconnect! if @switcher
      @confings = nil
      @switcher = nil
      Thread.current[OCTOSHARK] = nil
    end

    def reload!
      raise_not_configured_error unless @configs
      disconnect!
      @switcher = ConnectionSwitcher.new(@configs)
    end

    def switcher
      @switcher || raise_not_configured_error
    end

    private
    def raise_not_configured_error
      raise NotConfiguredError, "Octoshark is not setup"
    end
  end
end
