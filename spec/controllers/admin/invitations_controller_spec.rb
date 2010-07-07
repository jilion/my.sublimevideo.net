require 'spec_helper'

describe Admin::InvitationsController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true)
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with success to GET :new" do
      controller.stub!(:resource_name => :admin)
      get :new
      response.should be_success
    end
    it "should respond with success to GET :new" do
      controller.stub!(:resource_name => :user)
      get :new
      response.should be_success
    end
    
    it "should respond with success to POST :create" do
      controller.stub!(:resource_name => :admin)
      post :create, :admin => { :email => 'remy@jilion.com'}
      response.should redirect_to(admin_admins_url)
    end
    it "should respond with success to POST :create" do
      controller.stub!(:resource_name => :user)
      post :create, :user => { :email => 'remy@jilion.com'}
      response.should redirect_to(admin_users_url)
    end
  end
  
  context "with logged in user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    
    it "should respond with success to GET :edit" do
      controller.stub!(:resource_name => :admin)
      get :edit, :invitation_token => '1'
      response.should be_success
    end
    it "should respond with success to GET :edit" do
      controller.stub!(:resource_name => :user)
      get :edit, :invitation_token => '1'
      response.should redirect_to(sites_url)
    end
    
    it "should respond with redirect to POST :create" do
      post :create, :admin => { :email => 'remy@jilion.com'}
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :user => { :email => 'remy@jilion.com'}
      response.should redirect_to(new_admin_session_path)
    end
    
    it "should respond with success to PUT :update" do
      put :update, :admin => { :password => '', :invitation_token => '' }
      response.should redirect_to(sites_url)
    end
    it "should respond with success to PUT :update" do
      put :update, :user => { :password => '', :full_name => '', :invitation_token => '' }
      response.should redirect_to(sites_url)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    
    it "should respond with redirect to POST :create" do
      controller.stub!(:resource_name => :admin)
      post :create, :admin => { :email => 'remy@jilion.com'}
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      controller.stub!(:resource_name => :user)
      post :create, :user => { :email => 'remy@jilion.com'}
      response.should redirect_to(new_admin_session_path)
    end
    
    describe "accept admin invitation" do
      before(:each) { controller.stub!(:resource_name => :admin) }
      
      it "should respond with redirect to GET :edit" do
        get :edit, :invitation_token => '1'
        response.should be_success
      end
      
      it "should respond with redirect to PUT :update" do
        controller.stub_chain(:resource, :errors, :empty?).and_return(true)
        controller.stub!(:sign_in => mock_admin)
        put :update, :admin => { :password => '123456', :invitation_token => '1' }
        response.should redirect_to(admin_admins_url)
      end
      
      it "should respond with redirect to PUT :update" do
        controller.stub_chain(:resource, :errors, :empty?).and_return(false)
        put :update, :admin => { :password => '123456', :invitation_token => '1' }
        response.should be_success
      end
    end
    
    describe "accept user invitation" do
      before(:each) { controller.stub!(:resource_name => :user) }
      
      it "should respond with redirect to GET :edit" do
        get :edit, :invitation_token => '1'
        response.should be_success
      end
      
      it "should respond with redirect to PUT :update" do
        controller.stub_chain(:resource, :errors, :empty?).and_return(true)
        controller.stub!(:sign_in => mock_user)
        put :update, :user => { :password => '123456', :full_name => 'John Doe', :invitation_token => '1' }
        response.should redirect_to(sites_url)
      end
      
      it "should respond with redirect to PUT :update" do
        controller.stub_chain(:resource, :errors, :empty?).and_return(false)
        put :update, :user => { :password => '123456', :full_name => 'John Doe', :invitation_token => '1' }
        response.should be_success
      end
    end
    
  end
  
private
  
  def mock_admin(stubs={})
    @mock_admin ||= mock_model(Admin, stubs)
  end
  
  def mock_user(stubs={})
    @mock_user ||= mock_model(User, stubs)
  end
  
end