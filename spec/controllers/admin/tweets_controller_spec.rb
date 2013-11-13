require 'spec_helper'

describe Admin::TweetsController do

  context "with logged in admin with the twitter role" do
    before { sign_in :admin, authenticated_admin(roles: ['twitter']) }

    it "responds with success to GET :index" do
      get :index
      expect(response).to be_success
      expect(response).to render_template(:index)
    end

    it "responds with success to PUT :favorite" do
      expect(Tweet).to receive(:find).with('1') { mock_tweet }
      expect(mock_tweet).to receive(:favorite!)

      put :favorite, id: '1'
      expect(response).to redirect_to admin_tweets_path
    end
  end

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :index, put: :favorite }

end
