require 'spec_helper'

describe Admin::ReferrersController do

  context "with logged in admin" do
    before :each do
      sign_in :admin, authenticated_admin
    end

    it "responds with success to GET :index" do
      get :pages
      response.should be_success
      response.should render_template(:pages)
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :pages }

end
