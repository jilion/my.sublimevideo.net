require 'spec_helper'

describe Admin::DelayedJobsController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before(:each) do
      sign_in :admin, logged_in_admin
      Delayed::Job.stub(:find).with("1").and_return(mock_delayed_job)
    end
    
    it "should respond with success to GET :index" do
      Delayed::Job.stub(:all).and_return([])
      
      get :index
      response.should be_success
    end
    
    it "should respond with success to GET :show" do
      get :show, :id => '1'
      response.should be_success
    end
    
    it "should respond with redirect to PUT :update" do
      mock_delayed_job.stub(:update_attributes).with({ :locked_at => nil, :locked_by => nil }).and_return(true)
      
      put :update, :id => '1'
      response.should be_redirect
      response.should redirect_to admin_delayed_jobs_path
    end
    
    it "should respond with redirect to DELETE :destroy" do
      mock_delayed_job.stub(:destroy).and_return(true)
      
      delete :destroy, :id => '1'
      response.should be_redirect
      response.should redirect_to admin_delayed_jobs_path
    end
  end
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :show" do
      get :show, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to DELETE :destroy" do
      delete :destroy, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :show" do
      get :show, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to DELETE :destroy" do
      delete :destroy, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
  end
  
end