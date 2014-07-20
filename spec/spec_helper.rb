require 'octoshark'


# Load support files
ROOT = File.expand_path('../', File.dirname(__FILE__))
Dir["#{ROOT}/spec/support/**/*.rb"].each { |f| require f }


RSpec.configure do |config|
  config.include Helpers

  config.before :each do
    ActiveRecord::Base.establish_connection({adapter: 'sqlite3', database: 'tmp/default.sqlite'})
    Octoshark.reset!
  end
end
