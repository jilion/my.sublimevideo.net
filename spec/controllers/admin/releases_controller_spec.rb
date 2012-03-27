require 'spec_helper'

describe Admin::ReleasesController do

  context "with logged in admin with the player role" do
    before(:each) { sign_in :admin, authenticated_admin(roles: ['player']) }

    it "responds with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end

    describe "POST :create" do
      before(:each) { Release.stub(:new).and_return(mock_release) }

      it "responds with redirect when save succeed" do
        mock_release.stub(:save) { true }

        post :create, release: {}
        response.should redirect_to(admin_releases_path)
      end

      it "responds with success when save fails" do
        mock_release.stub(:save) { false }

        post :create, release: {}
        response.should be_success
        response.should render_template(:index)
      end
    end

    describe "PUT :update" do
      before(:each) { Release.stub(:find).and_return(mock_release) }

      it "responds with redirect when update_attributes succeed" do
        mock_release.stub(:flag).and_return(true)

        put :update, id: '1', release: {}
        response.should redirect_to(admin_releases_path)
      end

      it "responds with success when update_attributes fails" do
        mock_release.stub(:flag).and_return(false)

        put :update, id: '1', release: {}
        response.should be_success
        response.should render_template(:index)
      end
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:authenticated_user, :guest], { get: :index, post: :create, put: :update }
  it_should_behave_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { get: :index, post: :create, put: :update }

end
