require 'octoshark/version'
require 'active_record'
require 'octoshark/active_record_extensions'

module Octoshark
  autoload :ConnectionManager, 'octoshark/connection_manager'
  autoload :Error,             'octoshark/error'
end
