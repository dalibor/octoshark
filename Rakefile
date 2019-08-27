require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yaml'
require 'mysql2'
require 'octoshark'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :db do
  task :establish_connection do
    configs    = YAML.load_file('spec/support/config.yml')
    config     = configs['db1'].reject { |k, v| k == 'database' }
    @databases = configs.map { |_, config| config['database'] }
    ActiveRecord::Base.establish_connection(config)
  end

  task :create => :establish_connection do
    @databases.each do |database|
      begin
        ActiveRecord::Base.connection.create_database(database, charset: 'utf8')
        puts "#{database} created."
      rescue ActiveRecord::StatementInvalid => e
        if e.message.match /database exists/
          puts "#{database} exists."
        else
          raise e
        end
      end
    end
  end

  task :drop => :establish_connection do
    @databases.each do |database|
      ActiveRecord::Base.connection.drop_database(database)
    end
  end
end
