require 'spec_helper'

describe Users::RegistrationsController do
  
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:user] }
  
  context "with logged in user" do
    before :each do
      sign_in :user, logged_in_user2
      User.stub(:find).and_return(logged_in_user2)
    end
    
    context "with wrong password" do
      before(:each) { logged_in_user2.stub(:valid_password?).with('abcd').and_return(false) }
      
      describe "PUT :update" do
        it "should redirect to /account/edit" do
          put :update, :password => 'abcd'
          request.flash[:alert].should be_present
          response.should redirect_to(edit_user_registration_url)
        end
      end
      
      describe "DELETE :destroy" do
        it "should redirect to /account/edit with a wrong password" do
          delete :destroy, :password => 'abcd'
          request.flash[:alert].should be_present
          response.should redirect_to(edit_user_registration_url)
        end
      end
    end
      
    context "with good password" do
      before(:each) { logged_in_user2.stub(:valid_password?).with('123456').and_return(true) }
      
      describe "PUT :update" do
        it "should redirect to /sites when update_attributes succeed" do
          logged_in_user2.stub(:update_with_password).and_return(true)
          
          put :update, :password => '123456'
          request.flash[:alert].should be_nil
          response.should redirect_to(edit_user_registration_url)
        end
        
        it "should redirect to /sites/:token/edit when update_attributes fail" do
          logged_in_user2.stub(:update_with_password).and_return(false)
          logged_in_user2.should_receive(:errors).any_number_of_times.and_return(["error"])
          
          put :update, :password => '123456'
          request.flash[:alert].should be_nil
          response.should render_template(:edit)
        end
      end
      
      describe "DELETE :destroy" do
        it "should redirect to /sites with a good password" do
          delete :destroy, :password => '123456'
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end
  
end