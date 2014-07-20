require 'spec_helper'

describe Octoshark do

  describe ".setup" do
    it "creates connection switcher" do
      Octoshark.setup({})

      expect(Octoshark.switcher).to_not be_nil
    end
  end

  describe ".reset!" do
    it "removes connection switcher" do
      Octoshark.setup({})
      Octoshark.reset!

      expect { Octoshark.switcher }.to raise_error(Octoshark::NotConfiguredError)
    end

    it "cleans octoshark thread key" do
      Octoshark.setup({})
      Octoshark.reset!

      expect(Thread.current[Octoshark::OCTOSHARK]).to be_nil
    end
  end

  describe ".reload!" do
    it "replaces connection switcher" do
      Octoshark.setup({})
      switcher = Octoshark.switcher

      Octoshark.reload!

      expect(Octoshark.switcher).to_not be_nil
      expect(Octoshark.switcher).to_not eq(switcher)
    end
  end

  describe ".switcher" do
    it "returns connection switcher" do
      Octoshark.setup({})

      expect(Octoshark.switcher).to be_an_instance_of(Octoshark::ConnectionSwitcher)
    end

    it "raises 'NotConfiguredError' error if not setup" do
      expect { Octoshark.switcher }.to raise_error(Octoshark::NotConfiguredError)
    end
  end

  [
    :current_connection, :with_connection,
    :connection, :current_or_default_connection,
    :connection_pools, :find_connection_pool
  ].each do |method_name|
    describe ".#{method_name}" do
      it "delegates #{method_name} to connection switcher" do
        Octoshark.setup({})
        expect(Octoshark.switcher).to receive(method_name)

        Octoshark.send(method_name)
      end
    end
  end
end
