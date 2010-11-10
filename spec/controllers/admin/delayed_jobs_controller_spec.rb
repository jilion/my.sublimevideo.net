require 'spec_helper'

describe Admin::DelayedJobsController do
  
  context "with logged in admin" do
    before(:each) do
      sign_in :admin, authenticated_admin
      Delayed::Job.stub(:find).with('1') { mock_delayed_job }
    end
    
    it "should respond with success to GET :index" do
      Delayed::Job.stub(:all).and_return([])
      
      get :index
      response.should be_success
      response.should render_template(:index)
    end
    
    it "should respond with success to GET :show" do
      get :show, :id => '1'
      response.should be_success
      response.should render_template(:show)
    end
    
    it "should respond with redirect to PUT :update" do
      mock_delayed_job.stub(:update_attributes).with({ :locked_at => nil, :locked_by => nil }) { true }
      
      put :update, :id => '1'
      response.should be_redirect
      response.should redirect_to admin_delayed_jobs_path
    end
    
    it "should respond with redirect to DELETE :destroy" do
      mock_delayed_job.stub(:destroy) { true }
      
      delete :destroy, :id => '1'
      response.should be_redirect
      response.should redirect_to admin_delayed_jobs_path
    end
  end
  
  it_should_behave_like "redirect when connected", '/admin/login', [:user, :guest], { :get => [:index, :show], :put => :update, :delete => :destroy }
  
end