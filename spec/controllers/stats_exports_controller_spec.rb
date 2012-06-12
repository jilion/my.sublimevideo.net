require 'spec_helper'

describe StatsExportsController do

  verb_and_actions = { get: [:show], post: :create }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions#, id: '1'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], verb_and_actions

  describe "GET #show", :fog_mock do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user ) }
    let(:stats_export) { create(:stats_export, st: site.token) }

    before { sign_in user }

    it "redirects to S3 authenticated url" do
      get :show, id: stats_export.id
      response.body.should include CGI::escapeHTML(stats_export.file.secure_url)
      response.status.should eq 302
    end

    it "verify that current_user own the stats export" do
      other_stats_export = create(:stats_export)
      get :show, id: other_stats_export.id
      response.status.should eq 401
    end
  end

  describe "POST #create" do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user ) }
    let(:stats_exporter) { stub }
    let(:delay_stub) { stub }

    before { sign_in user }

    it "delay stats export and notification" do
      StatsExporter.should_receive(:new).with(site.token, 1, 2) { stats_exporter }
      stats_exporter.should_receive(:delay).with(priority: 50) { delay_stub }
      delay_stub.should_receive(:create_and_notify_export!)
      post :create, stats_export: { st: site.token, from: 1, to: 2 }
      response.should be_success
    end

    it "verify that current_user own the site_token" do
      post :create, stats_export: { st: 'other_site_token', from: 1, to: 2 }
      response.status.should eq 401
    end

  end

end
