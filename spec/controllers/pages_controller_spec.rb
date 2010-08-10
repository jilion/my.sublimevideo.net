require 'spec_helper'

describe PagesController do
  include Devise::TestHelpers
  
  context "with logged in unsuspended user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => false)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    %w[terms docs].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should be_success
      end
    end
    
    it "should redirect to root path with GET :show, on suspended page" do
      get :show, :page => 'suspended'
      response.should redirect_to(root_path)
    end
  end
  
  context "with logged in suspended user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => true)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    %w[terms docs].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should be_success
      end
    end
    
    it "should respond with success to GET :show, on suspended page" do
      get :show, :page => 'suspended'
      response.should be_success
    end
  end
  
  context "as guest" do
    %w[terms docs].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should be_success
      end
    end
    
    it "should redirect to /sites with GET :show, on suspended page" do
      get :show, :page => 'suspended'
      response.should redirect_to(new_user_session_path)
    end
  end
  
end