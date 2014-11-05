require 'octoshark/version'
require 'active_record'
require 'octoshark/active_record_extensions'

module Octoshark
  autoload :ConnectionSwitcher, 'octoshark/connection_switcher'

  class NotConfiguredError < RuntimeError; end
  class NoConnectionError < StandardError; end;
  class NoCurrentConnectionError < StandardError; end;

  OCTOSHARK = :octoshark

  class << self
    delegate :connection_pools,
      :current_or_default_connection,
      :disconnect!,
      :find_connection_pool,
      :with_connection,
      :current_connection,
      to: :switcher

    def configure(configs)
      @configs = configs
      @switcher = ConnectionSwitcher.new(configs)
    end

    def reset!
      return unless configured?
      disconnect!
      @confings = nil
      @switcher = nil
      Thread.current[OCTOSHARK] = nil
    end

    def reload!
      raise_not_configured_error unless @configs
      disconnect!
      @switcher = ConnectionSwitcher.new(@configs)
    end

    def configured?
      !@switcher.nil?
    end

    def switcher
      @switcher || raise_not_configured_error
    end

    private
    def raise_not_configured_error
      raise NotConfiguredError, "Octoshark is not configured, use Octoshark.configure"
    end
  end
end
