require 'spec_helper'

describe Admin::TweetsController do

  context "with logged in admin with the twitter role" do
    before { sign_in :admin, authenticated_admin(roles: ['twitter']) }

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

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :index, put: :favorite }

end
