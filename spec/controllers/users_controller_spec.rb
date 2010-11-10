require 'spec_helper'

describe UsersController do
  
  context "with logged in user" do
    before(:each) do
      sign_in :user, logged_in_user
      User.stub(:find).and_return(logged_in_user)
    end
    
    it "should respond with success to PUT :update" do
      logged_in_user.should_receive(:update_attributes).with({}).and_return(true)
      
      put :update, :id => '1', :user => {}
      response.should redirect_to(edit_user_registration_path)
    end
    
    it "should respond not with success to PUT :update with invalid params" do
      logged_in_user.should_receive(:update_attributes).with({}).and_return(false)
      logged_in_user.should_receive(:errors).any_number_of_times.and_return(["error"])
      
      put :update, :id => '1', :user => {}
      response.should render_template('users/registrations/edit')
    end
  end
  
  context "as guest" do
    it "should respond with success to PUT :update" do
      put :update, :id => '1', :user => {}
      response.should redirect_to(new_user_session_path)
    end
  end
  
end