require 'fast_spec_helper'
require 'pusher'
require File.expand_path('lib/pusher_wrapper')

require File.expand_path('spec/config/redis')
$redis = Redis.new unless defined?($redis)

describe PusherWrapper, :redis do
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
    let(:webhook) { stub(:webhook) }
    let(:channel_name) { 'channel_name' }
    before { webhook.stub(:events) { [event] } }

    context "with 'channel_occupied' event" do
      let(:event) { {
        'name' => 'channel_occupied',
        'channel' => channel_name
      } }

      it "adds channel_name to Redis Set" do
        PusherWrapper.handle_webhook(webhook)
        $redis.sismember("pusher:channels", channel_name).should be_true
      end
    end

    context "with 'channel_vacated' event" do
      let(:event) { {
        'name' => 'channel_vacated',
        'channel' => channel_name
      } }

      it "removes existing channel_name from Redis Set" do
        $redis.sadd("pusher:channels", channel_name)
        PusherWrapper.handle_webhook(webhook)
        $redis.sismember("pusher:channels", channel_name).should be_false
      end
    end
  end

  describe ".trigger" do
    let(:channel_name) { 'channel_name' }
    let(:event_name) { 'event_name' }
    let(:data) { { some: 'data' } }

    context "with channel occupied" do
      before { $redis.sadd("pusher:channels", channel_name) }

      it "triggers Pusher channel_name" do
        Pusher[channel_name].should_receive(:trigger!).with(event_name, data)
        PusherWrapper.trigger(channel_name, event_name, data).should be_true
      end
    end

    context "with channel vacated" do
      it "triggers Pusher channel_name" do
        Pusher[channel_name].should_not_receive(:trigger!).with(event_name, data)
        PusherWrapper.trigger(channel_name, event_name, data).should be_false
      end
    end
  end

end
