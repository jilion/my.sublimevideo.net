require 'fast_spec_helper'
require 'pusher'

require 'models/pusher_channel'
require 'wrappers/pusher_wrapper'

describe PusherWrapper do
  before { Pusher.url = 'http://c76b85222fbec28c8508:7ab0d643924b2bcc23d2@api.pusherapp.com/apps/8211' }

  describe ".authenticated_response" do
    it "generates an authentication endpoint response" do
      PusherWrapper.authenticated_response('channel_name', 'socket_id').should eq(
        auth: "c76b85222fbec28c8508:2d6bed1ddb62cbefcd919bec6894905e5e9a053d1871f29956cb05f788dbe353"
      )
    end
  end

  describe ".key" do
    it "extracts key from url" do
      PusherWrapper.key.should eq('c76b85222fbec28c8508')
    end
  end

  describe ".handle_webhook" do
    let(:webhook) { stub(:webhook, events: [event] ) }
    let(:channel_name) { 'channel_name' }
    let(:channel) { mock(PusherChannel) }

    before { PusherChannel.should_receive(:new).with(channel_name) { channel } }

    context "with 'channel_occupied' event" do
      let(:event) { {
        'name' => 'channel_occupied',
        'channel' => channel_name
      } }

      it "set channel occupied" do
        channel.should_receive(:occupied!)
        PusherWrapper.handle_webhook(webhook)
      end
    end

    context "with 'channel_vacated' event" do
      let(:event) { {
        'name' => 'channel_vacated',
        'channel' => channel_name
      } }

      it "set channel vacated" do
        channel.should_receive(:vacated!)
        PusherWrapper.handle_webhook(webhook)
      end
    end
  end

  describe ".trigger" do
    let(:event_name) { 'event_name' }
    let(:data) { { some: 'data' } }
    let(:channel_name) { 'channel_name' }
    let(:channel) { mock(PusherChannel, to_s: channel_name) }
    before { PusherChannel.should_receive(:new).with(channel_name) { channel } }

    context "with public channel" do
      before { channel.stub(:public?) { true } }

      it "doesn't triggers Pusher channel_name" do
        Pusher.should_receive(:trigger).with(channel_name, event_name, data)
        PusherWrapper.trigger(channel_name, event_name, data).should be_true
      end
    end

    context "with private channel" do
      before { channel.stub(:public?) { false } }

      context "occupied" do
        before { channel.stub(:occupied?) { true } }

        it "triggers Pusher channel_name" do
          Pusher.should_receive(:trigger).with(channel_name, event_name, data)
          PusherWrapper.trigger(channel_name, event_name, data).should be_true
        end
      end

      context "vacated" do
        before { channel.stub(:occupied?) { false } }

        it "doesn't triggers Pusher channel_name" do
          Pusher.should_not_receive(:trigger)
          PusherWrapper.trigger(channel_name, event_name, data).should be_false
        end
      end
    end
  end

end
