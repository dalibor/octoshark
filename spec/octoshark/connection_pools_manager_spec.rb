require 'spec_helper'

describe Octoshark::ConnectionPoolsManager do
  describe "#initialize" do
    it "initializes connection manager with default connection" do
      manager = Octoshark::ConnectionPoolsManager.new

      expect(manager.connection_pools.length).to eq(0)
      expect(manager.connection_pools[:default]).to be_nil
    end

    it "initializes connection manager with custom connections" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      expect(manager.connection_pools.length).to eq(2)
      expect(manager.connection_pools[:db1]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
      expect(manager.connection_pools[:db2]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "accepts configs with string keys" do
      configs = { 'db1' => { 'adapter' => "sqlite3", 'database' => "tmp/db1.sqlite" } }
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      expect { manager.connection_pools[:db1].connection }.not_to raise_error
    end
  end

  describe '#find_connection_pool' do
    it "can find connection pool by name" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)
      expect(manager.find_connection_pool(:db1)).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "raises Octoshark::Error::NoConnection when no pool with that name" do
      manager = Octoshark::ConnectionPoolsManager.new({})
      expect { manager.find_connection_pool(:invalid) }.to raise_error(Octoshark::Error::NoConnection)
    end
  end

  describe '#with_connection' do
    it "can use multiple connections" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      manager.with_connection(:db1) do
        expect(db(manager.current_connection)).to eq("db1")
      end

      manager.with_connection(:db2) do
        expect(db(manager.current_connection)).to eq("db2")
      end
    end

    it "can nest connection" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      manager.with_connection(:db1) do
        expect(db(manager.current_connection)).to eq("db1")

        manager.with_connection(:db2) do
          expect(db(manager.current_connection)).to eq("db2")
        end

        expect(db(manager.current_connection)).to eq("db1")
      end
    end

    it "returns value from execution" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)
      result = manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(result.first['1']).to eq(1)
    end

    it "raises Octoshark::Error::NoConnection" do
      manager = Octoshark::ConnectionPoolsManager.new({})

      expect { manager.with_connection(:invalid) }.to raise_error(Octoshark::Error::NoConnection)
    end

    context "using specific database", mysql2: true do
      it "can use specific database" do
        manager = Octoshark::ConnectionPoolsManager.new(mysql2_configs)

        db1 = mysql2_configs[:db1]['database']
        db2 = mysql2_configs[:db2]['database']

        manager.with_connection(:db1, db1) do
          expect(db(manager.current_connection)).to eq(db1)

          manager.with_connection(:db2, db2) do
            expect(db(manager.current_connection)).to eq(db2)
          end

          expect(db(manager.current_connection)).to eq(db1)
        end
      end

      it "sets database name on the connection" do
        manager = Octoshark::ConnectionPoolsManager.new(mysql2_configs)

        db1 = mysql2_configs[:db1]['database']

        manager.with_connection(:db1, db1) do |connection|
          expect(connection.database_name).to eq('octoshark_db1')
        end
      end

      it "returns value from execution" do
        manager = Octoshark::ConnectionPoolsManager.new(mysql2_configs)
        db1 = mysql2_configs[:db1]['database']
        result = manager.with_connection(:db1, db1) { |connection| connection.execute("SELECT 1") }.to_a
        expect(result).to eq([[1]])
      end
    end
  end

  describe "#disconnect!" do
    it "removes all connections from connection pools" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(manager.find_connection_pool(:db1)).to be_connected

      manager.disconnect!

      expect(manager.find_connection_pool(:db1)).to_not be_connected
    end
  end

  describe ".reset!" do
    it "gets new connection pools ready to rock" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(manager.connection_pools[:db1].connections.count).to eq(1)

      manager.reset!

      expect(manager.connection_pools[:db1].connections.count).to eq(0)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(manager.connection_pools[:db1].connections.count).to eq(1)
    end
  end

  describe ".reset_connection_managers!" do
    it "resets connection managers" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)
      old_pools = manager.connection_pools.map(&:object_id)

      Octoshark::ConnectionPoolsManager.reset_connection_managers!

      new_pools = manager.connection_pools.map(&:object_id)
      expect(new_pools).to_not eq(old_pools)
    end
  end

  describe ".disconnect!" do
    it "disconnects connection managers" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      Octoshark::ConnectionPoolsManager.disconnect!

      expect(Octoshark::ConnectionPoolsManager.connection_managers).to be_blank
    end

    it "cleans old connections" do
      manager = Octoshark::ConnectionPoolsManager.new(configs)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      manager.with_connection(:db2) { |connection| connection.execute("SELECT 1") }
      expect(manager.connection_pools[:db1].connections.count).to eq(1)
      expect(manager.connection_pools[:db2].connections.count).to eq(1)

      Octoshark::ConnectionPoolsManager.disconnect!

      expect(manager.connection_pools[:db1].connections.count).to eq(0)
      expect(manager.connection_pools[:db2].connections.count).to eq(0)
    end
  end
end
