require 'spec_helper'

describe Octoshark::ConnectionSwitcher do
  let(:config) { {
    db1: { adapter: "sqlite3", database: "tmp/db1.sqlite" },
    db2: { adapter: "sqlite3", database: "tmp/db2.sqlite" }
  } }

  def current_database_name(connection)
    connection.execute('PRAGMA database_list').first['file'].split('/').last
  end

  describe "#initialize" do
    it "can initialize connection switcher with default connection" do
      switcher = Octoshark::ConnectionSwitcher.new
      conn = ActiveRecord::Base.connection

      expect(switcher.connection_pools.length).to eq(1)
      expect(switcher.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "can initialize connection switcher with custom connections" do
      switcher = Octoshark::ConnectionSwitcher.new(config)

      expect(switcher.connection_pools.length).to eq(3)
      expect(switcher.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
      expect(switcher.connection_pools[:db1]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end
  end

  describe "#current_connection" do
    it "returns last used connection as current one" do
      switcher = Octoshark::ConnectionSwitcher.new(config)
      connection = switcher.connection(:db1)

      expect(switcher.current_connection).to eq(connection)
    end

    it "raises error when no current connection" do
      switcher = Octoshark::ConnectionSwitcher.new

      expect { switcher.current_connection }.to raise_error(Octoshark::NoCurrentConnectionError)
    end
  end

  describe "#current_or_default_connection" do
    it "returns last used connection as current one" do
      switcher = Octoshark::ConnectionSwitcher.new(config)
      connection = switcher.connection(:db1)

      expect(switcher.current_or_default_connection).to eq(connection)
    end

    it "returns default connection when no current connection" do
      switcher = Octoshark::ConnectionSwitcher.new
      connection = switcher.find_connection_pool(:default).connection

      expect(switcher.current_or_default_connection).to eq(connection)
    end
  end

  describe '#find_connection_pool' do
    it "can find connection pool by name" do
      switcher = Octoshark::ConnectionSwitcher.new(config)
      expect(switcher.find_connection_pool(:db1)).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "raises Octoshark::NoConnectionError when no pool with that name" do
      switcher = Octoshark::ConnectionSwitcher.new({})
      expect { switcher.find_connection_pool(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end

  describe "#connection" do
    it "returns useful connection from the pool" do
      switcher = Octoshark::ConnectionSwitcher.new(config)
      connection = switcher.connection(:db1)
      expect(current_database_name(connection)).to eq("db1.sqlite")
    end

    it "raises Octoshark::NoConnectionError" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      expect { switcher.connection(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end

  describe '#with_connection' do
    it "can select default connection" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      switcher.with_connection(:default) do |connection|
        expect(current_database_name(switcher.current_connection)).to eq("default.sqlite")
      end
    end

    it "can use multiple connections" do
      switcher = Octoshark::ConnectionSwitcher.new(config)

      switcher.with_connection(:default) do |connection|
        expect(current_database_name(switcher.current_connection)).to eq("default.sqlite")
      end

      switcher.with_connection(:db1) do |connection|
        expect(current_database_name(switcher.current_connection)).to eq("db1.sqlite")
      end

      switcher.with_connection(:db2) do |connection|
        expect(current_database_name(switcher.current_connection)).to eq("db2.sqlite")
      end
    end

    it "can nest connection" do
      switcher = Octoshark::ConnectionSwitcher.new(config)

      switcher.with_connection(:db1) do |connection|
        expect(current_database_name(switcher.current_connection)).to eq("db1.sqlite")

        switcher.with_connection(:db2) do |connection|
          expect(current_database_name(switcher.current_connection)).to eq("db2.sqlite")
        end

        expect(current_database_name(switcher.current_connection)).to eq("db1.sqlite")
      end
    end

    it "raises Octoshark::NoConnectionError" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      expect { switcher.with_connection(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end

  describe "#disconnect!" do
    it "removes all connections from connection pools" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      switcher.with_connection(:default) { |connection| connection.execute("SELECT 1") }
      expect(switcher.find_connection_pool(:default)).to be_connected

      switcher.disconnect!

      expect(switcher.find_connection_pool(:default)).to_not be_connected
    end
  end
end
