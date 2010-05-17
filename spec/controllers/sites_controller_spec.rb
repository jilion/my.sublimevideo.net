require 'spec_helper'

describe SitesController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with success to GET :index" do
      pending "Two consecutive stub_chain should work as expected as stated here ??:"
      # https://rspec.lighthouseapp.com/projects/5645/tickets/846-stub_chain-does-not-work-for-chains-that-only-differ-at-the-end
      # http://github.com/dchelimsky/rspec/commit/b691d54982e159426c9c7bb6a4f6fcdfe3f97183
      @mock_user.stub_chain(:sites, :scoped).and_return([])
      @mock_user.stub_chain(:sites, :build).and_return(mock_site)
      get :index
      response.should be_success
    end
    it "should respond with success to GET :show" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      get :show, :id => '1'
      response.should be_success
    end
    it "should respond with success to GET :edit" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      get :edit, :id => '1'
      response.should be_success
    end
    it "should respond with success to POST :create" do
      @mock_user.stub_chain(:sites, :build).with({}).and_return(mock_site)
      mock_site.stub(:save).and_return(true)
      mock_site.stub(:activate)
      post :create, :site => {}
      response.should redirect_to(sites_url)
    end
    it "should respond with success to PUT :update" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      mock_site.stub(:update_attributes).with({}).and_return(true)
      mock_site.stub(:deactivate)
      mock_site.stub(:activate)
      put :update, :id => '1', :site => {}
      response.should redirect_to(sites_url)
    end
    it "should respond with success to DELETE :destoy" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      mock_site.stub(:destroy)
      delete :destroy, :id => '1'
      response.should be_success
    end
  end
  
  context "as guest" do
    it "should respond with success to GET :index" do
      get :index
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with success to GET :show" do
      get :show, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with success to GET :edit" do
      get :edit, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with success to POST :create" do
      post :create, :site => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with success to PUT :update" do
      put :update, :id => '1', :site => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with success to DELETE :destoy" do
      delete :destroy, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
  end
  
private
  
  def mock_site(stubs={})
    @mock_site ||= mock_model(Site, stubs)
  end
  
end