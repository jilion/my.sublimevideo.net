require 'spec_helper'

describe Admin::TweetsController do

  context "with logged in admin" do
    before(:each) { sign_in :admin, authenticated_admin }

    it "responds with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end

    it "responds with success to PUT :favorite" do
      Tweet.should_receive(:find).with('1') { mock_tweet }
      mock_tweet.should_receive(:favorite!)

      put :favorite, id: '1'
      response.should redirect_to admin_tweets_path
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :index, put: :favorite }

end
