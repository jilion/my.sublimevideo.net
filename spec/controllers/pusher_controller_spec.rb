require 'spec_helper'

describe PusherController do

  describe "auth" do
    before { sign_in :user, authenticated_user }
    let(:channel_name) { 'a_channel' }

    context "with an accessible channel" do
      let(:socket_id) { 'socket_id' }

      it "return a json authenticated response" do
        authenticated_response = {}
        PusherChannel.stub(:new).with(channel_name) { stub(accessible?: true) }
        PusherWrapper.should_receive(:authenticated_response).with(channel_name, socket_id) {
          authenticated_response
        }
        post :auth, channel_name: channel_name, socket_id: socket_id
        response.body.should eq(authenticated_response.to_json)
      end
    end

    context "with a un-accessible channel" do
      it "return 'Not authorized' 403 status" do
        PusherChannel.stub(:new).with(channel_name) { stub(accessible?: false) }
        post :auth, channel_name: channel_name
        response.status.should eq(403)
      end
    end
  end

  describe "webhook" do
    let(:webhook) { stub(:webhook) }
    before { Pusher::WebHook.stub(:new).with(request) { webhook } }

    context "with valid webhook request" do
      before { webhook.stub(:valid?) { true } }

      it "handle webhook and render 'ok'" do
        PusherWrapper.should_receive(:handle_webhook).with(webhook)
        post :webhook
        response.body.should eq('ok')
      end
    end

    context "with unvalid webhook request" do
      before { webhook.stub(:valid?) { false } }

      it "return invalid 401 status" do
        post :webhook
        response.body.should eq('invalid')
        response.status.should eq(401)
      end
    end
  end

end
