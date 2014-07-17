require 'spec_helper'

describe Octoshark do

  it "can setup Octoshark with default connection" do
    Octoshark.setup({})
    expect(Octoshark.connection_manager).to_not be_nil
  end

  it "raises NotConfiguredError exception when not configured" do
    Octoshark.setup({})
    Octoshark.reset!
    expect { Octoshark.connection_manager }.to raise_error(Octoshark::NotConfiguredError)
  end

  [
    :current_connection, :with_connection, :connection,
    :connection_pools, :find_connection_pool
  ].each do |method_name|
    it "delegates #{method_name} to connection manager" do
      Octoshark.setup({})
      expect(Octoshark.connection_manager).to receive(method_name)

      Octoshark.send(method_name)
    end
  end
end
