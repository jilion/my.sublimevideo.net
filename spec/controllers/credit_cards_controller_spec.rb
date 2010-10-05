require 'spec_helper'

describe CreditCardsController do
  include Devise::TestHelpers
  include ControllerSpecHelpers
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    if MySublimeVideo::Release.public?
      it "should respond with success to GET :edit" do
        get :edit
        response.should be_success
      end
      it "should respond with success to PUT :update" do
        Invoice.stub(:current).with(@mock_user).and_return(mock_invoice)
        @mock_user.stub(:update_attributes).with({}).and_return(true)
        
        put :update, :user => {}
        response.should redirect_to(edit_user_registration_path)
      end
    else
      it "should respond with redirect to GET :edit" do
        get :edit
        response.should redirect_to(sites_path)
      end
      it "should respond with redirect to PUT :update" do
        put :update, :user => {}
        response.should redirect_to(sites_path)
      end
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :edit" do
      get :edit
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :user => {}
      response.should redirect_to(new_user_session_path)
    end
  end
  
end