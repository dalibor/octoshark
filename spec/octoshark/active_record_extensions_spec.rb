require 'spec_helper'
require 'logger'

describe "ActiveRecord Extensions" do
  it "logs current connection name" do
    io = StringIO.new
    logger = Logger.new(io)

    ActiveRecord::Base.logger = logger

    manager = Octoshark::ConnectionPoolsManager.new(configs)
    manager.with_connection(:db1) do |connection|
      connection.execute("SELECT 1")
    end

    expect(io.string).to include('[Octoshark: db1]')

    ActiveRecord::Base.logger = nil
  end

  it "logs current database name", mysql2: true do
    io = StringIO.new
    logger = Logger.new(io)
    database_name = mysql2_configs[:db1][:database]

    ActiveRecord::Base.logger = logger

    manager = Octoshark::ConnectionPoolsManager.new(mysql2_configs)
    manager.with_connection(:db1, database_name) do |connection|
      connection.execute("SELECT 1")
    end

    expect(io.string).to include("[Octoshark: db1 #{database_name}]")

    ActiveRecord::Base.logger = nil
  end

  it "logs the connection name for the Octoshark connection only" do
    io = StringIO.new
    logger = Logger.new(io)

    ActiveRecord::Base.logger = logger

    manager = Octoshark::ConnectionPoolsManager.new(configs)
    manager.with_connection(:db1) do |connection|
      ActiveRecord::Base.connection.execute("SELECT 1")
    end

    expect(io.string).not_to include('[Octoshark: db1]')

    ActiveRecord::Base.logger = nil
  end
end
