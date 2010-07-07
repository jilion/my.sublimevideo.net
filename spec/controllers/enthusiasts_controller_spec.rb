require 'spec_helper'

describe EnthusiastsController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before(:each) do
      @mock_user = mock_model(User, :active? => true)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with success to GET :new" do
      get :new
      response.should redirect_to(sites_path)
    end
    it "should respond with success to POST :create" do
      post :create, :enthusiast => {}
      response.should redirect_to(sites_path)
    end
  end
  
  context "as guest" do
    it "should respond with success to GET :new" do
      get :new
      response.should be_success
    end
    it "should respond with success to POST :create" do
      post :create, :enthusiast => { :email => 'test@test.com'}
      response.should redirect_to(root_path)
    end
  end
  
private
  
  def mock_enthusiast(stubs={})
    @enthusiast ||= mock_model(Enthusiast, stubs)
  end
  
end