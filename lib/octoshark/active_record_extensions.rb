module Octoshark
  module ActiveRecordBase
    extend ActiveSupport::Concern

    module ClassMethods
      def establish_connection(*)
        super
        Octoshark.reload! if Octoshark.configured?
      end
    end
  end

  module ActiveRecordLogSubscriber
    extend ActiveSupport::Concern

    def debug(msg)
      prefix = if Octoshark.configured? && Octoshark.current_connection_name
                 color("[Octoshark: #{Octoshark.current_connection_name}]",
                       ActiveSupport::LogSubscriber::GREEN, true)
               end
      super("#{prefix}#{msg}")
    end
  end
end

ActiveRecord::Base.send(:include, Octoshark::ActiveRecordBase)
ActiveRecord::LogSubscriber.send(:include, Octoshark::ActiveRecordLogSubscriber)
