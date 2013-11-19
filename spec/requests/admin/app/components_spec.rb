require 'spec_helper'

describe "Admin::App::Components JSON actions" do
  let(:component) { App::Component.create(name: 'name', token: 'token') }
  let(:headers) { { 'HTTP_HOST' => 'admin.sublimevideo.dev', 'HTTP_AUTHORIZATION' => "Token token=\"#{ENV['PLAYER_ACCESS_TOKEN']}\"" } }

  describe "Authentication" do
    context "Authorized token" do
      it "returns 200 response" do
        get "app/components.json", nil, headers
        response.status.should eq 200
      end
    end

    context "Non-Authorized token" do
      it "returns 200 response" do
        headers['HTTP_AUTHORIZATION'] = "Token token=\"argh\""
        get "app/components.json?auth_token=argh", nil, headers
        response.status.should eq 401
      end
    end

    context "No token" do
      it "returns an '401 Unauthorized' response" do
        headers['HTTP_AUTHORIZATION'] = nil
        get 'app/components.json', nil, headers
        response.status.should eq 401
      end
    end
  end

  describe "create" do
    context "valid params" do
      it "returns 201" do
        post "app/components.json", {
          component: {
            name: 'name',
            token: 'token'
          } }, headers
        response.status.should eq 201
      end
    end

    context "duplicated component" do
      it "returns 422" do
        post "app/components.json", {
          component: {
            name: component.name,
            token: component.token
          } }, headers
        response.status.should eq 422
      end
    end

    context "wrong params" do
      it "returns 422" do
        post "app/components.json", {
          component: {
            name: 'name'
          } }, headers
        response.status.should eq 422
      end
    end
  end

end
