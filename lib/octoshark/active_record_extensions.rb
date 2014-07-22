module Octoshark
  module EstablishConnectionWithOctosharkReloading
    def establish_connection(*)
      super
      Octoshark.reload! if Octoshark.configured?
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

ActiveRecord::Base.singleton_class.send(:prepend, Octoshark::EstablishConnectionWithOctosharkReloading)
ActiveRecord::LogSubscriber.send(:include, Octoshark::ActiveRecordLogSubscriber)
