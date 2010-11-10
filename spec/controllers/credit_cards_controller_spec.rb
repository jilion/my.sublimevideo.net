require 'spec_helper'

describe CreditCardsController do
  
  context "with a logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    context "with no credit card" do
      before(:each) { logged_in_user.stub!(:credit_card?) { false } }
      
      it "should redirect to /account/edit on GET :edit" do
        get :edit
        response.should redirect_to(edit_user_registration_path)
      end
      
      it "should redirect to /account/edit on PUT :update" do
        put :update, :user => {}
        response.should redirect_to(edit_user_registration_path)
      end
    end
    
    context "with a credit card" do
      before(:each) do
        logged_in_user.stub!(:credit_card?) { true }
        User.stub!(:find) { logged_in_user }
      end
      
      it "should respond with success on GET :edit" do
        get :edit
        response.should be_success
      end
      
      it "should redirect to /account/edit on PUT :update that succeed" do
        logged_in_user.should_receive(:update_attributes).with({}) { true }
        
        put :update, :user => {}
        response.should redirect_to(edit_user_registration_path)
      end
      
      it "should render :edit on PUT :update that fail" do
        logged_in_user.should_receive(:update_attributes).with({}) { false }
        logged_in_user.should_receive(:errors).any_number_of_times.and_return(["error"])
        
        put :update, :user => {}
        response.should be_success
        response.should render_template(:edit)
      end
    end
  end
  
  context "as guest" do
    it "should redirect to /login on GET :edit" do
      get :edit
      response.should redirect_to(new_user_session_path)
    end
    
    it "should redirect to /login on PUT :update" do
      put :update, :user => {}
      response.should redirect_to(new_user_session_path)
    end
  end
  
end