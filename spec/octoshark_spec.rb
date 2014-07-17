require 'spec_helper'

describe Octoshark do

  it "can setup octoshark with default connection" do
    Octoshark.setup({})
    expect(Octoshark.connection_manager).to_not be_nil
  end
end
