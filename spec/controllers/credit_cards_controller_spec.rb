require 'spec_helper'

describe CreditCardsController do
  
  context "with a logged in user" do
    before(:each) { sign_in :user, authenticated_user }
    
    it "should respond with success on GET :edit" do
      get :edit
      response.should be_success
    end
    
    it "should redirect to /account/edit on PUT :update that succeed" do
      authenticated_user.should_receive(:attributes=).with({})
      authenticated_user.should_receive(:check_credit_card) { nil } # authorization ok without 3-d secure
      authenticated_user.should_receive(:save) { true } # user is valid
      
      put :update, :user => {}
      response.should redirect_to(edit_user_registration_path)
    end
    
    it "should render :edit on PUT :update that needs a 3-D Secure check" do
      authenticated_user.should_receive(:attributes=).with({})
      authenticated_user.should_receive(:check_credit_card) { "<html></html>" } # authorization with 3-d secure
      
      put :update, :user => {}
      response.body.should == "<html></html>"
    end
    
    it "should render :edit on PUT :update that fail" do
      authenticated_user.should_receive(:attributes=).with({})
      authenticated_user.should_receive(:check_credit_card) { nil } # authorization not ok
      authenticated_user.should_receive(:save) { false } # auser is not valid
      
      put :update, :user => {}
      response.should render_template(:edit)
    end
  end
  
  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :edit, :put => :update }
  
end
