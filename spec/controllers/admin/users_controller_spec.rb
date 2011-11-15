require 'spec_helper'

describe Admin::UsersController do

  context "with logged in admin" do
    before(:each) { sign_in :admin, authenticated_admin }

    it "responds with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end

    it "responds with success to GET :show" do
      User.should_receive(:find).with('1') { mock_user }

      get :show, id: '1'
      response.should be_success
      response.should render_template(:show)
    end

    it "responds with success to GET :become" do
      User.should_receive(:find).with('1') { mock_user }
      controller.should_receive(:sign_in).with(:user, mock_user)

      get :become, id: '1'

      response.should redirect_to root_path
    end
  end

  it_should_behave_like "redirect when connected as", '/login', [:user, :guest], { get: [:index, :show, :become] }

end
