require 'fast_spec_helper'
require 'edge_cast'
require File.expand_path('lib/cdn/edgecast_wrapper')

describe CDN::EdgeCastWrapper do
  let(:edgecast) { mock('EdgeCast') }

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
    before { described_class.stub(:client) { edgecast } }

    describe "purge" do
      it "calls purge on http_small_object" do
        edgecast.should_receive(:purge).with(:http_small_object, "http://#{described_class.cname}/filepath.js")
        described_class.purge("/filepath.js")
      end
    end
  end

end
