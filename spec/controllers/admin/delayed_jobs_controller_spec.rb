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
  end
  
private
  
  def mock_delayed_job(stubs={})
    @mock_delayed_job ||= mock_model(Delayed::Job, stubs)
  end
  
end