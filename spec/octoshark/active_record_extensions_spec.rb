require 'spec_helper'

describe Octoshark::ActiveRecordExtensions do

  it "reloads Octoshark connection pools when establishing a new connection" do
    Octoshark.configure(configs)

    spec = ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection(spec)

    expect(ActiveRecord::Base.connection_pool).to eq(Octoshark.find_connection_pool(:default))
  end
end
