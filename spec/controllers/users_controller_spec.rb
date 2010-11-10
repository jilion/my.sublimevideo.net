require 'spec_helper'

describe UsersController do
  
  context "with logged in user" do
    before(:each) { sign_in :user, authenticated_user }
    
    it "should respond with success to PUT :update" do
      @current_user.should_receive(:update_attributes).with({}) { true }
      
      put :update, :id => '1', :user => {}
      response.should redirect_to(edit_user_registration_path)
    end
    
    it "should respond not with success to PUT :update with invalid params" do
      @current_user.should_receive(:update_attributes).with({}) { false }
      @current_user.should_receive(:errors).any_number_of_times.and_return(["error"])
      
      put :update, :id => '1', :user => {}
      response.should render_template('users/registrations/edit')
    end
  end
  
  it_should_behave_like "redirect when connected", '/login', [:guest], { :put => :update }, nil
  
end