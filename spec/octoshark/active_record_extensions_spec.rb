require 'spec_helper'
require 'logger'

describe "ActiveRecord Extensions" do
  it "reloads connection pools when establishing a new connection" do
    Octoshark.configure(configs)

    spec = ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection(spec)

    expect(ActiveRecord::Base.connection_pool).to eq(Octoshark.find_connection_pool(:default))
  end

  it "logs current connection name" do
    io = StringIO.new
    logger = Logger.new(io)

    ActiveRecord::Base.logger = logger

    Octoshark.configure(configs)
    Octoshark.with_connection(:db1) do |connection|
      connection.execute("SELECT 1")
    end

    expect(io.string).to include('[Octoshark: db1]')

    ActiveRecord::Base.logger = nil
  end
end
