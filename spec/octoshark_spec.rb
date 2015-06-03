require 'spec_helper'

describe Octoshark do

  describe ".reconnect!" do
    it "reconnects connection managers" do
      manager = Octoshark::ConnectionManager.new(configs)
      old_pools = manager.connection_pools.map(&:object_id)

      Octoshark.reconnect!

      new_pools = manager.connection_pools.map(&:object_id)
      expect(new_pools).to_not eq(old_pools)
    end
  end

  describe ".reset!" do
    it "removes connection managers" do
      manager = Octoshark::ConnectionManager.new(configs)

      Octoshark.reset!

      expect(Octoshark.connection_managers).to be_blank
    end

    it "cleans old connections" do
      manager = Octoshark::ConnectionManager.new(configs)

      check_connections_clean_up(manager, :db1) { Octoshark.reset! }
    end
  end
end
