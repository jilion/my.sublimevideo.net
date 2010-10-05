require 'spec_helper'

describe UsersController do
  include Devise::TestHelpers
  include ControllerSpecHelpers
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with success to PUT :update" do
      logged_in_user.stub(:update_attributes).with({}).and_return(true)
      
      put :update, :id => '1', :user => {}
      response.should redirect_to(edit_user_registration_path)
    end
  end
  
  context "as guest" do
    it "should respond with success to PUT :update" do
      put :update, :id => '1', :user => {}
      response.should redirect_to(new_user_session_path)
    end
  end
  
end