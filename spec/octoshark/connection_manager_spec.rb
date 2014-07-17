require 'spec_helper'

describe Octoshark::ConnectionManager do
  let(:config) { { conn1: { adapter: "sqlite3", database: "tmp/conn1.sqlite" } } }

  describe "#initialize" do
    it "can initialize connection manager with default connection" do
      manager = Octoshark::ConnectionManager.new
      conn = ActiveRecord::Base.connection

      expect(manager.connection_pools.length).to eq(1)
      expect(manager.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "can initialize connection manager with custom connections" do
      manager = Octoshark::ConnectionManager.new(config)

      expect(manager.connection_pools.length).to eq(2)
      expect(manager.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
      expect(manager.connection_pools[:conn1]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end
  end

  describe "#current_connection" do
    it "returns default connection as current one" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.current_connection).to eq(ActiveRecord::Base.connection)
    end
  end

  describe '#find_connection_pool' do
    it "can find connection pool by name" do
      manager = Octoshark::ConnectionManager.new(config)
      expect(manager.find_connection_pool(:conn1)).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "raises Octoshark::NoConnectionError when no pool with that name" do
      manager = Octoshark::ConnectionManager.new({})
      expect { manager.find_connection_pool(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end
end
