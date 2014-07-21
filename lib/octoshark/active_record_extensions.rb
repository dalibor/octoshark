module Octoshark
  module ActiveRecordBase
    extend ActiveSupport::Concern

    included do
      class << self
        alias_method_chain :establish_connection, :octoshark
      end
    end

    module ClassMethods
      def establish_connection_with_octoshark(*args)
        establish_connection_without_octoshark(*args)
        Octoshark.reload! if Octoshark.configured?
      end
    end
  end

  module ActiveRecordLogSubscriber
    extend ActiveSupport::Concern

    included do
      alias_method_chain :debug, :octoshark
    end

    def debug_with_octoshark(msg)
      prefix = if Octoshark.configured? && Octoshark.current_connection_name
                 color("[Octoshark: #{Octoshark.current_connection_name}]",
                       ActiveSupport::LogSubscriber::GREEN, true)
               end
      debug_without_octoshark("#{prefix}#{msg}")
    end
  end
end

ActiveRecord::Base.send(:include, Octoshark::ActiveRecordBase)
ActiveRecord::LogSubscriber.send(:include, Octoshark::ActiveRecordLogSubscriber)
