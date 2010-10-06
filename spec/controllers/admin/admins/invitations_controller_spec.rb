require 'spec_helper'

describe Admin::Admins::InvitationsController do
  include Devise::TestHelpers
  
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:admin] }
  
  context "with logged in admin" do
    before(:each) { sign_in :admin, logged_in_admin }
    
    it "should respond with success to GET :new" do
      get :new
      response.should be_success
    end
    
    it "should respond with redirect to POST :create" do
      post :create, :admin => { :email => 'remy@jilion.com' }
      response.should redirect_to(admin_admins_url)
    end
  end
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :admin => { :email => 'remy@jilion.com' }
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    
    it "should respond with redirect to POST :create" do
      post :create, :admin => { :email => 'remy@jilion.com' }
      response.should redirect_to(new_admin_session_path)
    end
  end
  
end