require 'yaml'

module Helpers

  def configs
    {
      db1: { adapter: "sqlite3", database: "tmp/db1.sqlite" },
      db2: { adapter: "sqlite3", database: "tmp/db2.sqlite" }
    }
  end

  def mysql2_configs
    YAML.load_file('spec/support/config.yml').with_indifferent_access
  end

  def db(connection)
    case connection
    when ActiveRecord::ConnectionAdapters::SQLite3Adapter
      connection.execute('PRAGMA database_list').first['file'].split('/').last.split('.').first
    when ActiveRecord::ConnectionAdapters::Mysql2Adapter
      connection.instance_variable_get(:@config)[:database]
    end
  end
end
