require 'spec_helper'

describe Octoshark do

  describe ".configure" do
    it "creates connection switcher" do
      Octoshark.configure({})

      expect(Octoshark.switcher).to_not be_nil
    end
  end

  describe ".reset!" do
    it "removes connection switcher" do
      Octoshark.configure({})
      Octoshark.reset!

      expect { Octoshark.switcher }.to raise_error(Octoshark::NotConfiguredError)
    end

    it "cleans octoshark thread key" do
      Octoshark.configure({})
      Octoshark.reset!

      expect(Thread.current[Octoshark::OCTOSHARK]).to be_nil
    end

    it "cleans old connections" do
      check_connections_clean_up { Octoshark.reset! }
    end
  end

  describe ".reload!" do
    it "replaces connection switcher" do
      Octoshark.configure({})
      switcher = Octoshark.switcher

      Octoshark.reload!

      expect(Octoshark.switcher).to_not be_nil
      expect(Octoshark.switcher).to_not eq(switcher)
    end

    it "clears old switcher connections" do
      check_connections_clean_up { Octoshark.reload! }
    end
  end

  describe ".configured?" do
    it "is not configured by default" do
      expect(Octoshark.configured?).to be_falsey
    end

    it "is configured is switcher is configured" do
      Octoshark.configure({})

      expect(Octoshark.configured?).to be_truthy
    end
  end

  describe ".switcher" do
    it "returns connection switcher" do
      Octoshark.configure({})

      expect(Octoshark.switcher).to be_an_instance_of(Octoshark::ConnectionSwitcher)
    end

    it "raises 'NotConfiguredError' error if not configured" do
      expect { Octoshark.switcher }.to raise_error(Octoshark::NotConfiguredError)
    end
  end

  [
    :current_connection, :with_connection,
    :connection, :current_or_default_connection,
    :connection_pools, :find_connection_pool,
    :disconnect!
  ].each do |method_name|
    describe ".#{method_name}" do
      it "delegates #{method_name} to connection switcher" do
        Octoshark.configure({})
        expect(Octoshark.switcher).to receive(method_name)

        Octoshark.send(method_name)
      end
    end
  end
end
