module Octoshark
  module EstablishConnectionWithOctosharkReloading
    def establish_connection(*)
      super
      Octoshark.reload! if Octoshark.configured?
    end
  end

  module ActiveRecordAbstractAdapter
    attr_accessor :connection_name

    def log(sql, name = "SQL", *other_args)
      if connection_name
        name = "[Octoshark: #{connection_name}] #{name}"
      end

      super(sql, name, *other_args)
    end
  end
end

ActiveRecord::Base.singleton_class.send(:prepend, Octoshark::EstablishConnectionWithOctosharkReloading)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:prepend, Octoshark::ActiveRecordAbstractAdapter)
