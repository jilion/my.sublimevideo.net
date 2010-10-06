require 'spec_helper'

describe PagesController do
  include Devise::TestHelpers
  
  context "with logged in unsuspended user" do
    before(:each) { sign_in :user, logged_in_user(:suspended? => false) }
    
    %w[terms privacy].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should be_success
      end
    end
    
    if MySublimeVideo::Release.public?
      it "should redirect to root path with GET :show, on suspended page" do
        get :show, :page => 'suspended'
        response.should redirect_to(root_path)
      end
    end
  end
  
  context "with logged in suspended user" do
    before(:each) { sign_in :user, logged_in_user(:suspended? => true) }
    
    %w[terms privacy].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should be_success
      end
    end
    
    if MySublimeVideo::Release.public?
      it "should respond with success to GET :show, on suspended page" do
        get :show, :page => 'suspended'
        response.should be_success
      end
    end
  end
  
  context "as guest" do
    %w[terms privacy].each do |page|
      it "should respond with success to GET :show, on #{page} page" do
        get :show, :page => page
        response.should be_success
      end
    end
    
    if MySublimeVideo::Release.public?
      it "should redirect to /sites with GET :show, on suspended page" do
        get :show, :page => 'suspended'
        response.should redirect_to(new_user_session_path)
      end
    end
  end
  
end