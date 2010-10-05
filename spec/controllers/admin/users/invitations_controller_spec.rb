require 'spec_helper'

describe Admin::Users::InvitationsController do
  include Devise::TestHelpers
  include ControllerSpecHelpers
  
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:user] }
  
  context "with logged in admin" do
    before(:each) { sign_in :admin, logged_in_admin }
    
    it "should respond with success to GET :new" do
      get :new
      response.should be_success
    end
    
    describe "POST :create" do
      before(:each) { User.stub!(:invite) { mock_user } }
      
      it "should respond with success if invite succeed" do
        mock_user.stub!(:invited? => true)
        post :create, :user => { :email => "remy@jilion.com" }
        response.should redirect_to(admin_users_url)
      end
      it "should respond with success if invite fail" do
        mock_user.stub!(:invited? => false)
        post :create, :user => { :email => "remy@jilion.com" }
        response.should be_success
        response.should render_template("new")
      end
    end
  end
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :user => { :email => "remy@jilion.com" }
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :user => { :email => "remy@jilion.com" }
      response.should redirect_to(new_admin_session_path)
    end
  end
  
end