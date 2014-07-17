require 'spec_helper'

describe Octoshark::ConnectionManager do
  let(:config) { {
    db1: { adapter: "sqlite3", database: "tmp/db1.sqlite" },
    db2: { adapter: "sqlite3", database: "tmp/db2.sqlite" }
  } }

  def current_database_name(connection)
    connection.execute('PRAGMA database_list').first['file'].split('/').last
  end

  describe "#initialize" do
    it "can initialize connection manager with default connection" do
      manager = Octoshark::ConnectionManager.new
      conn = ActiveRecord::Base.connection

      expect(manager.connection_pools.length).to eq(1)
      expect(manager.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "can initialize connection manager with custom connections" do
      manager = Octoshark::ConnectionManager.new(config)

      expect(manager.connection_pools.length).to eq(3)
      expect(manager.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
      expect(manager.connection_pools[:db1]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end
  end

  describe "#current_connection" do
    it "returns default connection as current one" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.current_connection).to eq(manager.connection(:default))
    end

    it "returns last used connection as current one" do
      manager = Octoshark::ConnectionManager.new(config)
      connection = manager.connection(:db1)

      expect(manager.current_connection).to eq(connection)
    end
  end

  describe '#find_connection_pool' do
    it "can find connection pool by name" do
      manager = Octoshark::ConnectionManager.new(config)
      expect(manager.find_connection_pool(:db1)).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "raises Octoshark::NoConnectionError when no pool with that name" do
      manager = Octoshark::ConnectionManager.new({})
      expect { manager.find_connection_pool(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end

  describe "#connection" do
    it "returns useful connection from the pool" do
      manager = Octoshark::ConnectionManager.new(config)
      connection = manager.connection(:db1)
      expect(current_database_name(connection)).to eq("db1.sqlite")
    end

    it "raises Octoshark::NoConnectionError" do
      manager = Octoshark::ConnectionManager.new({})

      expect { manager.connection(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end

  describe '#with_connection' do
    it "can select default connection" do
      manager = Octoshark::ConnectionManager.new({})

      manager.with_connection(:default) do |connection|
        expect(current_database_name(manager.current_connection)).to eq("default.sqlite")
      end
    end

    it "can use multiple connections" do
      manager = Octoshark::ConnectionManager.new(config)

      manager.with_connection(:default) do |connection|
        expect(current_database_name(manager.current_connection)).to eq("default.sqlite")
      end

      manager.with_connection(:db1) do |connection|
        expect(current_database_name(manager.current_connection)).to eq("db1.sqlite")
      end

      manager.with_connection(:db2) do |connection|
        expect(current_database_name(manager.current_connection)).to eq("db2.sqlite")
      end
    end

    it "can nest connection" do
      manager = Octoshark::ConnectionManager.new(config)

      manager.with_connection(:db1) do |connection|
        expect(current_database_name(manager.current_connection)).to eq("db1.sqlite")

        manager.with_connection(:db2) do |connection|
          expect(current_database_name(manager.current_connection)).to eq("db2.sqlite")
        end

        expect(current_database_name(manager.current_connection)).to eq("db1.sqlite")
      end
    end

    it "raises Octoshark::NoConnectionError" do
      manager = Octoshark::ConnectionManager.new({})

      expect { manager.with_connection(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end
end
