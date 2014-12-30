require 'spec_helper'

describe Octoshark::ConnectionSwitcher do
  describe "#initialize" do
    it "initializes connection switcher with default connection" do
      switcher = Octoshark::ConnectionSwitcher.new

      expect(switcher.connection_pools.length).to eq(1)
      expect(switcher.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "initializes connection switcher with custom connections" do
      switcher = Octoshark::ConnectionSwitcher.new(configs)

      expect(switcher.connection_pools.length).to eq(3)
      expect(switcher.connection_pools[:default]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
      expect(switcher.connection_pools[:db1]).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "accepts configs with string keys" do
      configs = { 'db1' => { 'adapter' => "sqlite3", 'database' => "tmp/db1.sqlite" } }
      switcher = Octoshark::ConnectionSwitcher.new(configs)

      expect { switcher.connection_pools[:db1].connection }.not_to raise_error
    end
  end

  describe "#current_connection" do
    it "returns last used connection as current one" do
      switcher = Octoshark::ConnectionSwitcher.new(configs)
      switcher.with_connection(:db1) do |connection|
        expect(switcher.current_connection).to eq(connection)
      end
    end

    it "raises error when no current connection" do
      switcher = Octoshark::ConnectionSwitcher.new

      expect { switcher.current_connection }.to raise_error(Octoshark::NoCurrentConnectionError)
    end
  end

  describe "#current_connection?" do
    it "returns true if current one" do
      switcher = Octoshark::ConnectionSwitcher.new(configs)
      switcher.with_connection(:db1) do
        expect(switcher.current_connection?).to be_truthy
      end
    end

    it "returns false if no current one" do
      switcher = Octoshark::ConnectionSwitcher.new

      expect(switcher.current_connection?).to be_falsey
    end
  end

  describe "#current_or_default_connection" do
    it "returns current connection" do
      switcher = Octoshark::ConnectionSwitcher.new(configs)
      switcher.with_connection(:db1) do |db1|
        expect(switcher.current_or_default_connection).to eq(db1)
      end
    end

    it "returns default connection when no current connection" do
      switcher = Octoshark::ConnectionSwitcher.new
      default = switcher.find_connection_pool(:default).connection

      expect(switcher.current_or_default_connection).to eq(default)
    end
  end

  describe '#find_connection_pool' do
    it "can find connection pool by name" do
      switcher = Octoshark::ConnectionSwitcher.new(configs)
      expect(switcher.find_connection_pool(:db1)).to be_an_instance_of(ActiveRecord::ConnectionAdapters::ConnectionPool)
    end

    it "raises Octoshark::NoConnectionError when no pool with that name" do
      switcher = Octoshark::ConnectionSwitcher.new({})
      expect { switcher.find_connection_pool(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end

  describe '#with_connection' do
    it "can select default connection" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      switcher.with_connection(:default) do
        expect(db(switcher.current_connection)).to eq("default")
      end
    end

    it "can use multiple connections" do
      switcher = Octoshark::ConnectionSwitcher.new(configs)

      switcher.with_connection(:default) do
        expect(db(switcher.current_connection)).to eq("default")
      end

      switcher.with_connection(:db1) do
        expect(db(switcher.current_connection)).to eq("db1")
      end

      switcher.with_connection(:db2) do
        expect(db(switcher.current_connection)).to eq("db2")
      end
    end

    it "can nest connection" do
      switcher = Octoshark::ConnectionSwitcher.new(configs)

      switcher.with_connection(:db1) do
        expect(db(switcher.current_connection)).to eq("db1")

        switcher.with_connection(:db2) do
          expect(db(switcher.current_connection)).to eq("db2")
        end

        expect(db(switcher.current_connection)).to eq("db1")
      end
    end

    it "returns value from execution" do
      switcher = Octoshark::ConnectionSwitcher.new({})
      result = switcher.with_connection(:default) { |connection| connection.execute("SELECT 1") }
      expect(result).to eq([{"1"=>1, 0=>1}])
    end

    it "raises Octoshark::NoConnectionError" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      expect { switcher.with_connection(:invalid) }.to raise_error(Octoshark::NoConnectionError)
    end
  end

  describe '#without_connection' do
    it "can reset current connection temporarily inside nested connection block" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      switcher.with_connection(:default) do
        expect(db(switcher.current_connection)).to eq("default")

        switcher.without_connection do
          expect { switcher.current_connection }.to raise_error(Octoshark::NoCurrentConnectionError)
        end

        expect(db(switcher.current_connection)).to eq("default")
      end
    end
  end

  describe "#disconnect!" do
    it "removes all connections from connection pools" do
      switcher = Octoshark::ConnectionSwitcher.new({})

      switcher.with_connection(:default) { |connection| connection.execute("SELECT 1") }
      expect(switcher.find_connection_pool(:default)).to be_connected

      switcher.disconnect!

      expect(switcher.find_connection_pool(:default)).to_not be_connected
    end
  end
end
