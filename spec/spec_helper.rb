require 'octoshark'

RSpec.configure do |config|
  config.before :each do
    ActiveRecord::Base.establish_connection(YAML.load(File.read('spec/config/database.yml')))
  end
end
