require 'spec_helper'

describe CreditCardsController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    context "public release only", :release => :public do
      it "should respond with success to GET :edit" do
        get :edit
        response.should be_success
      end
      it "should respond with success to PUT :update" do
        Invoice.should_receive(:current).with(@mock_user) { mock_invoice }
        @mock_user.should_receive(:update_attributes).with({}).and_return(true)
        
        put :update, :user => {}
        response.should redirect_to(edit_user_registration_path)
      end
    end
    
    context "public release only", :release => :beta do
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