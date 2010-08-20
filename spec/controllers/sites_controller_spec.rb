require 'spec_helper'

describe SitesController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => false)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with success to GET :index" do
      @mock_user.stub_chain(:sites, :not_archived, :by_date).and_return([])
      get :index
      response.should be_success
    end
    it "should respond with success to GET :show" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      get :show, :id => '1', :format => :js
      response.should be_success
    end
    it "should respond with success to GET :state" do
      mock_site.stub(:active?).and_return(true)
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      get :state, :id => '1', :format => :js
      response.should be_success
    end
    it "should respond with success to GET :new" do
      @mock_user.stub_chain(:sites, :build).and_return(mock_site)
      get :new, :format => :js
      response.should be_success
    end
    it "should respond with success to GET :edit" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      get :edit, :id => '1', :format => :js
      response.should be_success
    end
    it "should respond with success to POST :create" do
      @mock_user.stub_chain(:sites, :build).with({}).and_return(mock_site)
      mock_site.stub(:save).and_return(true)
      mock_site.stub_chain(:delay, :activate).and_return(true)
      post :create, :site => {}
      response.should redirect_to(sites_url)
    end
    it "should respond with success to PUT :update" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      mock_site.stub(:update_attributes).with({}).and_return(true)
      mock_site.stub(:deactivate)
      mock_site.stub_chain(:delay, :activate).and_return(true)
      put :update, :id => '1', :site => {}
      response.should redirect_to(sites_url)
    end
    it "should respond with success to DELETE :destroy" do
      @mock_user.stub_chain(:sites, :find).with("1").and_return(mock_site)
      mock_site.stub(:archive)
      delete :destroy, :id => '1'
      response.should redirect_to(sites_url)
    end
  end
  
  if MySublimeVideo::Release.public?
    context "with suspended logged in user" do
      before(:each) do
        @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => true)
        User.stub(:find).and_return(@mock_user)
        sign_in :user, @mock_user
      end
    
      it "should respond with success to GET :index" do
        get :index
        response.should redirect_to(page_path("suspended"))
      end
      it "should respond with success to GET :show" do
        get :show, :id => '1'
        response.should redirect_to(page_path("suspended"))
      end
      it "should respond with success to GET :new" do
        get :new
        response.should redirect_to(page_path("suspended"))
      end
      it "should respond with success to GET :edit" do
        get :edit, :id => '1'
        response.should redirect_to(page_path("suspended"))
      end
      it "should respond with success to GET :state" do
        get :state, :id => '1'
        response.should redirect_to(page_path("suspended"))
      end
      it "should respond with success to POST :create" do
        post :create, :site => {}
        response.should redirect_to(page_path("suspended"))
      end
      it "should respond with success to PUT :update" do
        put :update, :id => '1', :site => {}
        response.should redirect_to(page_path("suspended"))
      end
      it "should respond with success to DELETE :destroy" do
        delete :destroy, :id => '1'
        response.should redirect_to(page_path("suspended"))
      end
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :show" do
      get :show, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :edit" do
      get :edit, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :state" do
      get :state, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :site => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1', :site => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to DELETE :destroy" do
      delete :destroy, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
  end
  
private
  
  def mock_site(stubs = {})
    @mock_site ||= mock_model(Site, stubs)
  end
  
end