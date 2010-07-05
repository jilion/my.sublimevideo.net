require 'spec_helper'

describe Admin::DelayedJobsController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true)
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with success to GET :index" do
      Delayed::Job.stub(:all).and_return([])
      get :index
      response.should be_success
    end
    it "should respond with success to GET :show" do
      Delayed::Job.stub(:find).with("1").and_return(mock_delayed_job)
      get :show, :id => '1'
      response.should be_success
    end
    it "should respond with redirect to PUT :update" do
      Delayed::Job.stub(:find).with("1").and_return(mock_delayed_job)
      mock_delayed_job.stub(:update_attributes).with({ :locked_at => nil, :locked_by => nil }).and_return(true)
      put :update, :id => '1'
      response.should be_redirect
      response.should redirect_to admin_delayed_jobs_path
    end
    it "should respond with redirect to DELETE :destroy" do
      Delayed::Job.stub(:find).with("1").and_return(mock_delayed_job)
      mock_delayed_job.stub(:destroy).and_return(true)
      delete :destroy, :id => '1'
      response.should be_redirect
      response.should redirect_to admin_delayed_jobs_path
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
  
private
  
  def mock_delayed_job(stubs={})
    @mock_delayed_job ||= mock_model(Delayed::Job, stubs)
  end
  
end