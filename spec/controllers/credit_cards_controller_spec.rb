require 'spec_helper'

describe CreditCardsController do
  
  context "with a logged in user" do
    before(:each) { sign_in :user, authenticated_user }
    
    context "with no credit card" do
      before(:each) { @current_user.stub(:credit_card?).and_return(false) }
      
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
      before(:each) { @current_user.stub(:credit_card?).and_return(true) }
      
      it "should respond with success on GET :edit" do
        get :edit
        response.should be_success
      end
      
      it "should redirect to /account/edit on PUT :update that succeed" do
        @current_user.should_receive(:update_attributes).with({}) { true }
        
        put :update, :user => {}
        response.should redirect_to(edit_user_registration_path)
      end
      
      it "should render :edit on PUT :update that fail" do
        @current_user.should_receive(:update_attributes).with({}) { false }
        @current_user.should_receive(:errors).any_number_of_times.and_return(["error"])
        
        put :update, :user => {}
        response.should be_success
        response.should render_template(:edit)
      end
    end
  end
  
  it_should_behave_like "redirect when connected", '/login', [:guest], { :get => :edit, :put => :update }
  
end