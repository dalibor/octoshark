require 'spec_helper'

describe Octoshark do

  describe ".reset_connection_managers!" do
    it "resets connection managers" do
      manager = Octoshark::ConnectionManager.new(configs)
      old_pools = manager.connection_pools.values(&:object_id)

      Octoshark.reset_connection_managers!

      new_pools = manager.connection_pools.values(&:object_id)
      expect(new_pools).to_not eq(old_pools)
    end
  end

  describe ".disconnect!" do
    it "disconnects connection managers" do
      manager = Octoshark::ConnectionManager.new(configs)

      Octoshark.disconnect!

      expect(Octoshark.connection_managers).to be_blank
    end

    it "cleans old connections" do
      manager = Octoshark::ConnectionManager.new(configs)

      manager.with_connection(:db1) { |connection| connection.execute("SELECT 1") }
      manager.with_connection(:db2) { |connection| connection.execute("SELECT 1") }
      expect(manager.connection_pools[:db1].connections.count).to eq(1)
      expect(manager.connection_pools[:db2].connections.count).to eq(1)

      Octoshark.disconnect!

      expect(manager.connection_pools[:db1].connections.count).to eq(0)
      expect(manager.connection_pools[:db2].connections.count).to eq(0)
    end
  end
end
