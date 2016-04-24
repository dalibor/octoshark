require 'octoshark/version'
require 'active_record'
require 'octoshark/active_record_extensions'

module Octoshark
  autoload :CurrentConnection,      'octoshark/current_connection'
  autoload :ConnectionManager,      'octoshark/connection_manager'
  autoload :ConnectionPoolsManager, 'octoshark/connection_pools_manager'
  autoload :Error,                  'octoshark/error'
end
