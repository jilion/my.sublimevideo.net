require 'spec_helper'

describe My::SiteStatsController do

  verb_and_actions = { get: [:index, :videos] }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], verb_and_actions, site_id: '1'

  context "with demo site" do

    it "responds with success to GET :index" do
      get :index, site_id: 'demo'
      response.should_not be_redirect
    end

    it "responds with success to GET :index (token)" do
      get :index, token: 'demo'
      response.should_not be_redirect
    end

    it "responds with success to GET :videos" do
      get :videos, site_id: 'demo'
      response.should_not be_redirect
    end

  end

end
