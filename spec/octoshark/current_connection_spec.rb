require 'spec_helper'

describe "connection manager" do
  let(:config) { configs[:db1] }

  describe "#identifier" do
    it "has unique identifiers" do
      manager1 = Octoshark::ConnectionManager.new
      manager2 = Octoshark::ConnectionManager.new
      expect(manager1.identifier).to_not eq(manager2.identifier)
    end
  end

  describe "#current_connection" do
    it "returns last used connection as current one" do
      manager = Octoshark::ConnectionManager.new
      manager.with_connection(config) do |connection|
        expect(manager.current_connection).to eq(connection)
      end
    end

    it "raises error when no current connection" do
      manager = Octoshark::ConnectionManager.new

      expect { manager.current_connection }.to raise_error(Octoshark::Error::NoCurrentConnection)
    end
  end

  describe "#current_connection?" do
    it "returns true if current one" do
      manager = Octoshark::ConnectionManager.new
      manager.with_connection(config) do
        expect(manager.current_connection?).to be_truthy
      end
    end

    it "returns false if no current one" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.current_connection?).to be_falsey
    end
  end

  describe "#current_or_default_connection" do
    it "returns current connection" do
      manager = Octoshark::ConnectionManager.new
      manager.with_connection(config) do |connection|
        expect(manager.current_or_default_connection).to eq(connection)
      end
    end

    it "returns default connection when no current connection" do
      manager = Octoshark::ConnectionManager.new

      expect(manager.current_or_default_connection).to eq(ActiveRecord::Base.connection_pool.connection)
    end
  end

  describe '#without_connection' do
    it "can reset current connection temporarily inside nested connection block" do
      manager = Octoshark::ConnectionManager.new

      manager.with_connection(config) do
        expect(db(manager.current_connection)).to eq("db1")

        manager.without_connection do
          expect { manager.current_connection }.to raise_error(Octoshark::Error::NoCurrentConnection)
        end

        expect(db(manager.current_connection)).to eq("db1")
      end
    end
  end
end
