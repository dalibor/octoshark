require 'spec_helper'

describe Octoshark::ConnectionManager do
  describe "#initialize" do
    it "initializes connection manager with default connection" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.connection_pools.length).to eq(0)
      expect(manager.connection_pools[:default]).to be_nil
    end

    it "initializes connection manager with custom connections" do
      manager = Octoshark::ConnectionManager.new(configs)

      expect(manager.connection_pools.length).to eq(2)
      expect(manager.connection_pools[:db1]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
      expect(manager.connection_pools[:db2]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "accepts configs with string keys" do
      configs = { 'db1' => { 'adapter' => "sqlite3", 'database' => "tmp/db1.sqlite" } }
      manager = Octoshark::ConnectionManager.new(configs)

      expect { manager.connection_pools[:db1].connection }.not_to raise_error
    end
  end

  describe "#identifier" do
    it "has unique identifiers" do
      manager1 = Octoshark::ConnectionManager.new
      manager2 = Octoshark::ConnectionManager.new
      expect(manager1.identifier).to_not eq(manager2.identifier)
    end
  end

  describe "#current_connection" do
    it "returns last used connection as current one" do
      manager = Octoshark::ConnectionManager.new(configs)
      manager.with_connection(:db1) do |connection|
        expect(manager.current_connection).to eq(connection)
      end
    end

    it "raises error when no current connection" do
      manager = Octoshark::ConnectionManager.new

      expect { manager.current_connection }.to raise_error(Octoshark::Error::NoCurrentConnection)
    end
  end

  describe "#current_connection?" do
    it "returns true if current one" do
      manager = Octoshark::ConnectionManager.new(configs)
      manager.with_connection(:db1) do
        expect(manager.current_connection?).to be_truthy
      end
    end

    it "returns false if no current one" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.current_connection?).to be_falsey
    end
  end

  describe "#current_or_default_connection" do
    it "returns current connection" do
      manager = Octoshark::ConnectionManager.new(configs)
      manager.with_connection(:db1) do |db1|
        expect(manager.current_or_default_connection).to eq(db1)
      end
    end

    it "returns default connection when no current connection" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.current_or_default_connection).to eq(ActiveRecord::Base.connection_pool.connection)
    end
  end

  describe '#find_connection_pool' do
    it "can find connection pool by name" do
      manager = Octoshark::ConnectionManager.new(configs)
      expect(manager.find_connection_pool(:db1)).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "raises Octoshark::Error::NoConnection when no pool with that name" do
      manager = Octoshark::ConnectionManager.new({})
      expect { manager.find_connection_pool(:invalid) }.to raise_error(Octoshark::Error::NoConnection)
    end
  end

  describe '#with_connection' do
    it "can use multiple connections" do
      manager = Octoshark::ConnectionManager.new(configs)

      manager.with_connection(:db1) do
        expect(db(manager.current_connection)).to eq("db1")
      end

      manager.with_connection(:db2) do
        expect(db(manager.current_connection)).to eq("db2")
      end
    end

    it "can nest connection" do
      manager = Octoshark::ConnectionManager.new(configs)

      manager.with_connection(:db1) do
        expect(db(manager.current_connection)).to eq("db1")

        manager.with_connection(:db2) do
          expect(db(manager.current_connection)).to eq("db2")
        end

        expect(db(manager.current_connection)).to eq("db1")
      end
    end

    it "returns value from execution" do
      manager = Octoshark::ConnectionManager.new(configs)
      result = manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(result).to eq([{"1"=>1, 0=>1}])
    end

    it "raises Octoshark::Error::NoConnection" do
      manager = Octoshark::ConnectionManager.new({})

      expect { manager.with_connection(:invalid) }.to raise_error(Octoshark::Error::NoConnection)
    end

    context "using specific database", mysql2: true do
      it "can use specific database" do
        manager = Octoshark::ConnectionManager.new(mysql2_configs)

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

      it "returns value from execution" do
        manager = Octoshark::ConnectionManager.new(mysql2_configs)
        db1 = mysql2_configs[:db1]['database']
        result = manager.with_connection(:db1, db1) { |connection| connection.execute("SELECT 1") }.to_a
        expect(result).to eq([[1]])
      end
    end
  end

  describe "#with_new_connection" do
    it "creates temporary connection to database server" do
      manager = Octoshark::ConnectionManager.new
      result = manager.with_new_connection(:db1, configs[:db1]) do |connection|
        connection.execute("SELECT 1")
        expect(connection.database_name).to be_nil
      end

      expect(manager.connection_pools).to be_blank
    end

    it "creates temporary connection to specific database", mysql2: true do
      manager = Octoshark::ConnectionManager.new

      config = mysql2_configs[:db1]
      database_name = config['database']

      result = manager.with_new_connection(:db1, config, database_name) do |connection|
        connection.execute("SELECT 1")
        expect(connection.database_name).to eq(database_name)
      end

      expect(manager.connection_pools).to be_blank
    end

    it "returns query results with temporary connection" do
      manager = Octoshark::ConnectionManager.new
      result = manager.with_new_connection(:db1, configs[:db1]) { |connection| connection.execute("SELECT 1") }

      expect(result).to eq([{"1"=>1, 0=>1}])
    end
  end

  describe '#without_connection' do
    it "can reset current connection temporarily inside nested connection block" do
      manager = Octoshark::ConnectionManager.new(configs)

      manager.with_connection(:db1) do
        expect(db(manager.current_connection)).to eq("db1")

        manager.without_connection do
          expect { manager.current_connection }.to raise_error(Octoshark::Error::NoCurrentConnection)
        end

        expect(db(manager.current_connection)).to eq("db1")
      end
    end
  end

  describe "#disconnect!" do
    it "removes all connections from connection pools" do
      manager = Octoshark::ConnectionManager.new(configs)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(manager.find_connection_pool(:db1)).to be_connected

      manager.disconnect!

      expect(manager.find_connection_pool(:db1)).to_not be_connected
    end
  end

  describe ".reset!" do
    it "gets new connection pools ready to rock" do
      manager = Octoshark::ConnectionManager.new(configs)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(manager.connection_pools[:db1].connections.count).to eq(1)

      manager.reset!

      expect(manager.connection_pools[:db1].connections.count).to eq(0)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      expect(manager.connection_pools[:db1].connections.count).to eq(1)
    end
  end
end
