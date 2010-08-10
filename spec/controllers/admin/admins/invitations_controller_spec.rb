require 'spec_helper'

describe Admin::Admins::InvitationsController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      mock_admin = Factory(:admin)
      mock_admin.stub!(:confirmed? => true)
      sign_in :admin, mock_admin
    end
    
    describe "invite admin" do
      before(:each) { request.env['devise.mapping'] = Devise.mappings[:admin] }
      it "should respond with success to POST :create" do
        post :create, :admin => { :email => 'remy@jilion.com' }
        response.should redirect_to(admin_admins_url)
      end
    end
  end
  
  context "with logged in user" do
    before :each do
      mock_user = Factory(:user)
      mock_user.stub!(:active? => true, :confirmed? => true)
      sign_in :user, mock_user
    end
    
    describe "invite admin" do
      before(:each) { request.env['devise.mapping'] = Devise.mappings[:admin] }
      it "should respond with redirect to GET :new" do
        get :new
        response.should redirect_to(new_admin_session_path)
      end
    end
  end
  
  context "as guest" do
    describe "invite admin" do
      before(:each) { request.env['devise.mapping'] = Devise.mappings[:admin] }
      it "should respond with redirect to POST :create" do
        post :create, :admin => { :email => 'remy@jilion.com' }
        response.should redirect_to(new_admin_session_path)
      end
    end
  end
  
end