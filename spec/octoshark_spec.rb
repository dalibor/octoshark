require 'spec_helper'

describe Octoshark do

  it "can setup Octoshark with default connection" do
    Octoshark.setup({})
    expect(Octoshark.switcher).to_not be_nil
  end

  it "raises NotConfiguredError exception when not configured" do
    Octoshark.setup({})
    Octoshark.reset!
    expect { Octoshark.switcher }.to raise_error(Octoshark::NotConfiguredError)
  end

  [
    :current_connection, :with_connection,
    :connection, :current_or_default_connection,
    :connection_pools, :find_connection_pool
  ].each do |method_name|
    it "delegates #{method_name} to connection switcher" do
      Octoshark.setup({})
      expect(Octoshark.switcher).to receive(method_name)

      Octoshark.send(method_name)
    end
  end
end
