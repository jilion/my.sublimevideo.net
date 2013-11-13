require 'fast_spec_helper'

require 'wrappers/pusher_wrapper'

describe PusherWrapper do

  describe '.authenticated_response' do
    it 'generates an authentication endpoint response' do
      expect(described_class.authenticated_response('channel_name', 'socket_id')).to eq(
        auth: 'c76b85222fbec28c8508:2d6bed1ddb62cbefcd919bec6894905e5e9a053d1871f29956cb05f788dbe353'
      )
    end
  end

  describe '.key' do
    it 'extracts key from url' do
      expect(described_class.key).to eq('c76b85222fbec28c8508')
    end
  end

  describe '.handle_webhook' do
    let(:webhook) { double(:webhook, events: [event] ) }
    let(:channel_name) { 'channel_name' }
    let(:channel) { double(PusherChannel) }

    before { expect(PusherChannel).to receive(:new).with(channel_name) { channel } }

    context 'with "channel_occupied" event' do
      let(:event) { {
        'name' => 'channel_occupied',
        'channel' => channel_name
      } }

      it 'set channel occupied' do
        expect(channel).to receive(:occupied!)
        described_class.handle_webhook(webhook)
      end
    end

    context 'with "channel_vacated" event' do
      let(:event) { {
        'name' => 'channel_vacated',
        'channel' => channel_name
      } }

      it 'set channel vacated' do
        expect(channel).to receive(:vacated!)
        described_class.handle_webhook(webhook)
      end
    end
  end

  describe '.trigger' do
    let(:event_name) { 'event_name' }
    let(:data) { { some: 'data' } }
    let(:channel_name) { 'channel_name' }
    let(:channel) { double(PusherChannel, to_s: channel_name) }
    before { expect(PusherChannel).to receive(:new).with(channel_name) { channel } }

    context 'with public channel' do
      before { allow(channel).to receive(:public?) { true } }

      it 'do not triggers Pusher channel_name' do
        expect(Pusher).to receive(:trigger).with(channel_name, event_name, data)
        expect(described_class.trigger(channel_name, event_name, data)).to be_truthy
      end
    end

    context 'with private channel' do
      before { allow(channel).to receive(:public?) { false } }

      context 'occupied' do
        before { allow(channel).to receive(:occupied?) { true } }

        it 'triggers Pusher channel_name' do
          expect(Pusher).to receive(:trigger).with(channel_name, event_name, data)
          expect(described_class.trigger(channel_name, event_name, data)).to be_truthy
        end
      end

      context 'vacated' do
        before { allow(channel).to receive(:occupied?) { false } }

        it 'doe not triggers Pusher channel_name' do
          expect(Pusher).not_to receive(:trigger)
          expect(described_class.trigger(channel_name, event_name, data)).to be_falsey
        end
      end
    end
  end

end
