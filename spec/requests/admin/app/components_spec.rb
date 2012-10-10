# coding: utf-8
require 'spec_helper'

describe "Admin::App::Components JSON actions" do
  let(:admin) {
    admin = create(:admin, roles: ['player'])
    admin.reset_authentication_token!
    admin
  }
  let(:component) { App::Component.create({name: 'app', token: 'e'}, as: :admin) }
  let(:headers) { { 'HTTP_HOST' => 'admin.sublimevideo.dev' } }

  describe "Auhtentication" do
    context "Authorized token" do
      it "returns 200 response" do
        get "app/components.json?auth_token=#{admin.authentication_token}", nil, headers
        response.status.should eq 200
      end
    end

    context "Non-Authorized token" do
      it "returns 200 response" do
        get "app/components.json?auth_token=argh", nil, headers
        response.status.should eq 401
      end
    end

    context "No token" do
      it "returns an '401 Unauthorized' response" do
        get 'app/components.json', nil, headers
        response.status.should eq 401
      end
    end
  end

  describe "create" do
    context "valid params" do
      it "returns 201" do
        post "app/components.json?auth_token=#{admin.authentication_token}", {
          component: {
            name: 'app',
            token: 'e'
          } }, headers
        response.status.should eq 201
      end
    end

    context "duplicated component" do
      it "returns 422" do
        post "app/components.json?auth_token=#{admin.authentication_token}", {
          component: {
            name: component.name,
            token: component.token
          } }, headers
        response.status.should eq 422
      end
    end

    context "wrong params" do
      it "returns 422" do
        post "app/components.json?auth_token=#{admin.authentication_token}", {
          component: {
            name: 'e'
          } }, headers
        response.status.should eq 422
      end
    end
  end

end
