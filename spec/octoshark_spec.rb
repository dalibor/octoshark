require 'spec_helper'

describe Octoshark do

  it "can setup Octoshark with default connection" do
    Octoshark.setup({})
    expect(Octoshark.connection_manager).to_not be_nil
  end

  it "can reset Octoshark's connection manager" do
    Octoshark.setup({})
    Octoshark.reset!

    expect(Octoshark.connection_manager).to be_nil
  end
end
