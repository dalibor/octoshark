require 'spec_helper'
require 'logger'

describe "ActiveRecord Extensions" do
  it "reloads connection pools when establishing a new connection" do
    Octoshark.configure(configs)

    spec = ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection(spec)

    expect(Octoshark.find_connection_pool(:default)).to eq(ActiveRecord::Base.connection_pool)
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

  it "logs the connection name for the Octoshark connection only" do
    io = StringIO.new
    logger = Logger.new(io)

    ActiveRecord::Base.logger = logger

    Octoshark.configure(configs)
    Octoshark.with_connection(:db1) do |connection|
      ActiveRecord::Base.connection.execute("SELECT 1")
    end

    expect(io.string).not_to include('[Octoshark: db1]')

    ActiveRecord::Base.logger = nil
  end

  it "is resilient to other libraries alias_method_chaining #establish_connection" do
    class << ActiveRecord::Base
      def establish_connection_with_monkey_patching(*args)
        # Noop
        establish_connection_without_monkey_patching(*args)
      end
      alias_method_chain :establish_connection, :monkey_patching
    end

    spec = ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection(spec)
  end
end
