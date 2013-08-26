# encoding: utf-8
require 'spec_helper'

describe "Admin::App::Components JSON actions" do
  let(:admin) {
    admin = create(:admin, roles: ['player'])
    admin.reset_authentication_token!
    admin
  }
  let(:zip) { fixture_file_upload(Rails.root.join('spec/fixtures', "app/e.zip")) }
  let(:component) { App::Component.create(name: 'app', token: App::Component::APP_TOKEN) }
  let(:component_version) { App::ComponentVersion.create(token: component.token, version: '2.0.0', zip: fixture_file("app/e.zip")) }
  let(:headers) { { 'HTTP_HOST' => 'admin.sublimevideo.dev' } }

  describe "Auhtentication" do
    context "authorized token" do
      it "returns 200 response" do
        get "app/components/#{component.token}/versions.json?auth_token=#{admin.authentication_token}", nil, headers
        response.status.should eq 200
      end
    end

    context "not existing component token" do
      it "returns an '401 Unauthorized' response" do
        get "app/components/argh/versions.json?auth_token=#{admin.authentication_token}", nil, headers
        response.status.should eq 404
      end
    end

    context "non-authorized token" do
      it "returns 200 response" do
        get "app/components/#{component.token}/versions.json?auth_token=argh", nil, headers
        response.status.should eq 401
      end
    end

    context "no token" do
      it "returns an '401 Unauthorized' response" do
        get "app/components/#{component.token}/versions.json", nil, headers
        response.status.should eq 401
      end
    end
  end

  describe "index" do
    it "returns 200 & json" do
      component_version
      get "app/components/#{component.token}/versions.json?auth_token=#{admin.authentication_token}", nil, headers
      response.status.should eq 200
    end
  end

  describe "create" do
    context "valid params" do
      it "returns 201" do
        post "app/components/#{component.token}/versions.json?auth_token=#{admin.authentication_token}", {
          version: {
            version: '2.0.0',
            zip: zip,
            dependencies: { app: "2.0.0" }.to_json
          } }, headers
        response.status.should eq 201
      end
    end

    context "duplicated component" do
      it "returns 422" do
        post "app/components/#{component.token}/versions.json?auth_token=#{admin.authentication_token}", {
          version: {
            version: component_version.version,
            zip: zip
          } }, headers
        response.status.should eq 422
      end
    end

    context "wrong params" do
      it "returns 422" do
        post "app/components/#{component.token}/versions.json?auth_token=#{admin.authentication_token}", {
          version: {
            version: '2.0.0'
          } }, headers
        response.status.should eq 422
      end
    end
  end

end
