require 'fast_spec_helper'
require 'edge_cast'

require 'wrappers/edge_cast_wrapper'

describe EdgeCastWrapper do
  let(:edgecast) { mock('EdgeCast') }

  before { Librato.stub(:increment) }

  describe "client" do
    it "inits EdgeCast client" do
      described_class.instance_variable_set(:@client, nil) # avoid memoization
      EdgeCast.should_receive(:new).with(
        account_number: described_class.account_number,
        api_token: described_class.api_token
      ) { edgecast }
      described_class.send(:client)
    end
  end

  context "with client" do
    before {
      described_class.stub(:client) { edgecast }
      edgecast.stub(:purge)
    }

    describe "purge" do
      it "calls purge on http_small_object" do
        edgecast.should_receive(:purge).with(:http_small_object, "http://#{described_class.cname}/filepath.js")
        described_class.purge("/filepath.js")
      end

      it "increments metrics" do
        Librato.should_receive(:increment).with('cdn.purge', source: 'edgecast')
        described_class.purge("/filepath.js")
      end
    end
  end

end
