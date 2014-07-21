require 'octoshark'
require 'fileutils'

ROOT = File.expand_path('../', File.dirname(__FILE__))
TMP  = 'tmp'

# Load support files
Dir["#{ROOT}/spec/support/**/*.rb"].each { |f| require f }


RSpec.configure do |config|
  config.include Helpers

  config.before :suite do
    FileUtils.mkdir_p(TMP)
  end

  config.before :each do
    ActiveRecord::Base.establish_connection({adapter: 'sqlite3', database: 'tmp/default.sqlite'})
    Octoshark.reset!
  end

  config.after :suite do
    FileUtils.rm_rf(TMP)
  end
end
