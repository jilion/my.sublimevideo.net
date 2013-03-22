require 'spec_helper'

describe "Sites requests" do
  let!(:site1) { create(:site, hostname: 'google.com') }
  let!(:site2) { create(:site, hostname: 'facebook.com', first_billable_plays_at: Time.now.utc) }
  let!(:site3) { create(:site, created_at: 2.days.ago) }
  before { set_api_credentials }

  describe "index" do
    it "supports per scope" do
      get "private_api/sites.json", { per: 2 }, @env
      MultiJson.load(response.body).should have(2).sites
    end

    it "supports select scope" do
      get "private_api/sites.json", { select: %w[token hostname] }, @env
      video_tag = MultiJson.load(response.body).first
      video_tag.should have_key("token")
      video_tag.should have_key("hostname")
      video_tag.should_not have_key("dev_hostnames")
    end

    it "supports without_hostnames scope" do
      get "private_api/sites.json", { without_hostnames: ['google.com', 'facebook.com'] }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site3.token
    end

    it "supports created_on scope" do
      get "private_api/sites.json", { created_on: 2.days.ago }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site3.token
    end

    it "supports first_billable_plays_on_week scope" do
      get "private_api/sites.json", { first_billable_plays_on_week: Time.now.utc }, @env
      body = MultiJson.load(response.body)
      body.should have(1).site
      body[0]['token'].should eq site2.token
    end
  end

  describe "show" do
    it "finds site per token" do
      get "private_api/sites/#{site1.token}.json", {}, @env
      MultiJson.load(response.body).should_not have_key("site")
    end
  end
end
