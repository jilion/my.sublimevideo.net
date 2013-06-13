require 'fast_spec_helper'

require 'wrappers/edge_cast_wrapper'

describe EdgeCastWrapper do
  let(:client) { mock('EdgeCast') }

  before { Librato.stub(:increment) }

  describe '.client' do
    before { described_class.class_variable_set(:@@_client, nil) } # avoid memoization

    it 'inits EdgeCast client' do
      EdgeCast.should_receive(:new).with(
        account_number: ENV['EDGECAST_ACCOUNT_NUMBER'],
        api_token: ENV['EDGECAST_API_TOKEN']
      ).and_return(client)

      described_class.send(:client)
    end
  end

  context 'with client' do
    before do
      described_class.stub(:client) { client }
      client.stub(:purge)
    end

    describe 'purge' do
      it 'calls purge on http_small_object' do
        client.should_receive(:purge).with(:http_small_object, "http://#{ENV['EDGECAST_CNAME']}/filepath.js")

        described_class.purge('/filepath.js')
      end

      it 'increments metrics' do
        Librato.should_receive(:increment).with('cdn.purge', source: 'edgecast')

        described_class.purge('/filepath.js')
      end
    end
  end

end
