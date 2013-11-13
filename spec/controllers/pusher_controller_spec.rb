require 'spec_helper'

describe PusherController do

  describe "auth" do
    before { sign_in :user, authenticated_user }
    let(:channel_name) { 'a_channel' }

    context "with an accessible channel" do
      let(:socket_id) { 'socket_id' }

      it "return a json authenticated response" do
        authenticated_response = {}
        allow(PusherChannel).to receive(:new).with(channel_name) { double(accessible?: true) }
        expect(PusherWrapper).to receive(:authenticated_response).with(channel_name, socket_id) {
          authenticated_response
        }
        post :auth, channel_name: channel_name, socket_id: socket_id
        expect(response.body).to eq(authenticated_response.to_json)
      end
    end

    context "with a un-accessible channel" do
      it "return 'Not authorized' 403 status" do
        allow(PusherChannel).to receive(:new).with(channel_name) { double(accessible?: false) }
        post :auth, channel_name: channel_name
        expect(response.status).to eq(403)
      end
    end
  end

  describe "webhook" do
    let(:webhook) { double(:webhook) }
    before { allow(Pusher::WebHook).to receive(:new).with(request) { webhook } }

    context "with valid webhook request" do
      before { allow(webhook).to receive(:valid?) { true } }

      it "handle webhook and render 'ok'" do
        expect(PusherWrapper).to receive(:handle_webhook).with(webhook)
        post :webhook
        expect(response.body).to eq('ok')
      end
    end

    context "with unvalid webhook request" do
      before { allow(webhook).to receive(:valid?) { false } }

      it "return invalid 401 status" do
        post :webhook
        expect(response.body).to eq('invalid')
        expect(response.status).to eq(401)
      end
    end
  end

end
