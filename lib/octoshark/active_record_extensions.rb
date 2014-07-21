module Octoshark
  module ActiveRecordExtensions
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
end

ActiveRecord::Base.send(:include, Octoshark::ActiveRecordExtensions)
