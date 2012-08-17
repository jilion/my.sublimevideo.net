require 'spec_helper'

describe VideoTagsController do

  verb_and_actions = { get: [:show] }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: '1', id: '2'
  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], verb_and_actions, site_id: '1', id: '2'

  context "with demo site" do

    it "responds with success to GET :show" do
      Site.stub(:find_by_token!) { mock_model(Site, token: SiteToken[:www])}
      get :show, site_id: 'demo', id: '2'
      response.should_not be_redirect
    end

  end

end
