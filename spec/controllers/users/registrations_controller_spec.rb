require 'spec_helper'

describe Users::RegistrationsController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(sites_path)
    end
    
    it "should respond with redirect to POST :create" do
      post :create, :user => {}
      response.should redirect_to(sites_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_user_session_path)
    end
    
    it "should respond with redirect to POST :create" do
      post :create, :user => {}
      response.should redirect_to(new_user_session_path)
    end
  end
  
end