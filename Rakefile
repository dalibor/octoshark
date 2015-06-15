require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yaml'
require 'mysql2'
require 'octoshark'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :db do
  task :establish_connection do
    configs = YAML.load_file('spec/support/config.yml').with_indifferent_access
    config = configs[:db1]
    @database_names = configs.map { |id, config| config.delete('database') }
    ActiveRecord::Base.establish_connection(config)
  end

  task :create => :establish_connection do
    @database_names.each do |database_name|
      begin
        ActiveRecord::Base.connection.create_database(database_name)
        puts "#{database_name} created."
      rescue ActiveRecord::StatementInvalid => e
        if e.message.match /database exists/
          puts "#{database_name} exists."
        else
          raise e
        end
      end
    end
  end

  task :drop => :establish_connection do
    @database_names.each do |database_name|
      ActiveRecord::Base.connection.drop_database(database_name)
    end
  end
end
