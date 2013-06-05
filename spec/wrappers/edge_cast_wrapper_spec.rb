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
        account_number: ENV['EDGECAST_ACCOUNT_NUMBER'],
        api_token: ENV['EDGECAST_API_TOKEN']
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
        edgecast.should_receive(:purge).with(:http_small_object, "http://#{ENV['EDGECAST_CNAME']}/filepath.js")
        described_class.purge("/filepath.js")
      end

      it "increments metrics" do
        Librato.should_receive(:increment).with('cdn.purge', source: 'edgecast')
        described_class.purge("/filepath.js")
      end
    end
  end

end
