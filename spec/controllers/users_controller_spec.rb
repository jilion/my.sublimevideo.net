require 'spec_helper'

describe UsersController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before(:each) do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with success to PUT :update" do
      @mock_user.stub(:update_attributes).with({}).and_return(true)
      put :update, :id => '1', :user => {}
      response.should redirect_to(sites_url)
    end
  end
  
  context "as guest" do
    it "should respond with success to PUT :update" do
      put :update, :id => '1', :user => {}
      response.should redirect_to(new_user_session_path)
    end
  end
  
end