require 'spec_helper'

describe Octoshark::ConnectionManager do
  describe "#initialize" do
    it "initializes connection manager with default connection" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.connection_pools.length).to eq(1)
      expect(manager.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "initializes connection manager with custom connections" do
      manager = Octoshark::ConnectionManager.new(configs)

      expect(manager.connection_pools.length).to eq(3)
      expect(manager.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
      expect(manager.connection_pools[:db1]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "accepts configs with string keys" do
      configs = { 'db1' => { 'adapter' => "sqlite3", 'database' => "tmp/db1.sqlite" } }
      manager = Octoshark::ConnectionManager.new(configs)

      expect { manager.connection_pools[:db1].connection }.not_to raise_error
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
      default = manager.find_connection_pool(:default).connection

      expect(manager.current_or_default_connection).to eq(default)
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
    it "can select default connection" do
      manager = Octoshark::ConnectionManager.new({})

      manager.with_connection(:default) do
        expect(db(manager.current_connection)).to eq("default")
      end
    end

    it "can use multiple connections" do
      manager = Octoshark::ConnectionManager.new(configs)

      manager.with_connection(:default) do
        expect(db(manager.current_connection)).to eq("default")
      end

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
      manager = Octoshark::ConnectionManager.new({})
      result = manager.with_connection(:default) { |connection| connection.execute("SELECT 1") }
      expect(result).to eq([{"1"=>1, 0=>1}])
    end

    it "raises Octoshark::Error::NoConnection" do
      manager = Octoshark::ConnectionManager.new({})

      expect { manager.with_connection(:invalid) }.to raise_error(Octoshark::Error::NoConnection)
    end
  end

  describe '#without_connection' do
    it "can reset current connection temporarily inside nested connection block" do
      manager = Octoshark::ConnectionManager.new({})

      manager.with_connection(:default) do
        expect(db(manager.current_connection)).to eq("default")

        manager.without_connection do
          expect { manager.current_connection }.to raise_error(Octoshark::Error::NoCurrentConnection)
        end

        expect(db(manager.current_connection)).to eq("default")
      end
    end
  end

  describe "#disconnect!" do
    it "removes all connections from connection pools" do
      manager = Octoshark::ConnectionManager.new({})

      manager.with_connection(:default) { |connection| connection.execute("SELECT 1") }
      expect(manager.find_connection_pool(:default)).to be_connected

      manager.disconnect!

      expect(manager.find_connection_pool(:default)).to_not be_connected
    end
  end
end
