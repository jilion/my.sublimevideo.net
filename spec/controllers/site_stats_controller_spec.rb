require 'spec_helper'

describe SiteStatsController do

  verb_and_actions = { get: [:index, :videos] }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], verb_and_actions, site_id: '1'

  context "with demo site" do

    it "responds with success to GET :index" do
      Site.stub(:find_by_token!) { mock_model(Site, token: SiteToken[:www])}
      get :index, site_id: 'demo'
      response.should_not be_redirect
    end

    it "responds with success to GET :videos" do
      Site.stub(:find_by_token!) { mock_model(Site, token: SiteToken[:www])}
      Stat::Video.stub(:top_videos) { [] }
      get :videos, site_id: 'demo', format: :json
      response.should_not be_redirect
    end

  end

end
