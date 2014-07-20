require 'spec_helper'

describe Octoshark::ActiveRecordExtensions do

  it "reloads Octoshark when re-establishing new connection" do
    Octoshark.setup(configs)
    spec = ActiveRecord::Base.remove_connection

    expect { Octoshark.with_connection(:default) {} }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    expect { Octoshark.with_connection(:db1) {} }.not_to raise_error

    ActiveRecord::Base.establish_connection(spec)

    expect { Octoshark.with_connection(:default) {} }.not_to raise_error
    expect { Octoshark.with_connection(:db1) {} }.not_to raise_error
  end
end
