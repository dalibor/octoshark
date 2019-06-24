require 'spec_helper'

describe Octoshark::ConnectionManager do
  describe "#with_connection", mysql2: true do
    it "creates temporary connection to database server" do
      manager = Octoshark::ConnectionManager.new
      connection_reference = nil

      config = mysql2_configs[:db1]

      manager.with_connection(config.except(:database)) do |connection|
        connection_reference = connection

        connection.execute("SELECT 1")
        expect(connection.database_name).to be_nil
      end

      expect(connection_reference.active?).to eq(false)
    end

    it "creates temporary connection to specific database", mysql2: true do
      manager = Octoshark::ConnectionManager.new
      connection_reference = nil

      config = mysql2_configs[:db1]
      database_name = config.fetch('database')

      manager.with_connection(config) do |connection|
        connection_reference = connection

        connection.execute("SELECT 1")
        expect(connection.database_name).to eq(database_name)
      end

      expect(connection_reference.active?).to eq(false)
    end

    it "returns query results with temporary connection" do
      manager = Octoshark::ConnectionManager.new
      config = configs[:db1]
      result = manager.with_connection(config) do |connection|
        connection.execute("SELECT 1")
      end

      expect(result.first['1']).to eq(1)
    end
  end
end
