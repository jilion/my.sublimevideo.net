require 'spec_helper'

describe Users::RegistrationsController do
  
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:user] }
  
  context "with logged in user" do
    before(:each) { sign_in :user, authenticated_user }
    
    context "with wrong password" do
      before(:each) { @current_user.should_receive(:valid_password?).with('abcd').and_return(false) }
      
      describe "PUT :update" do
        it "should redirect to /account/edit" do
          put :update, :user => { :current_password => 'abcd' }
          request.flash[:alert].should be_present
          response.should redirect_to(edit_user_registration_url)
        end
      end
      
      describe "DELETE :destroy" do
        it "should redirect to /account/edit" do
          delete :destroy, :user => { :current_password => 'abcd' }
          request.flash[:alert].should be_present
          response.should redirect_to(edit_user_registration_url)
        end
      end
    end
      
    context "with good password" do
      before(:each) { @current_user.should_receive(:valid_password?).with('123456').and_return(true) }
      
      describe "PUT :update" do
        it "should redirect to /sites when update_attributes succeeds" do
          @current_user.stub(:update_with_password) { true }
          
          put :update, :user => { :current_password => '123456' }
          request.flash[:alert].should be_nil
          response.should redirect_to(edit_user_registration_url)
        end
        
        it "should redirect to /sites/:token/edit when update_attributes fails" do
          @current_user.stub(:update_with_password) { false }
          @current_user.should_receive(:errors).any_number_of_times.and_return(["error"])
          
          put :update, :user => { :current_password => '123456' }
          request.flash[:alert].should be_nil
          response.should render_template(:edit)
        end
      end
      
      describe "DELETE :destroy" do
        it "should redirect to /sites" do
          delete :destroy, :user => { :current_password => '123456' }
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end
  
end