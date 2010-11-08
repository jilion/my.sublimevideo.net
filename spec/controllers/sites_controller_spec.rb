require 'spec_helper'

describe SitesController do
  
  context "with logged in user" do
    before(:each) do
      sign_in :user, logged_in_user
      logged_in_user.stub_chain(:sites, :find_by_token).with('a1b2c3') { mock_site }
      User.stub(:find) { logged_in_user }
    end
    
    describe "GET :index" do
      before(:each) do
        logged_in_user.stub_chain(:sites, :not_archived, :with_plan, :with_addons, :by_date).and_return([mock_site])
        get :index
      end
      
      it "should assign sites array as @sites" do
        assigns(:sites).should == [mock_site]
      end
      
      it "should respond with success" do
        response.should be_success
      end
    end
    
    it "should respond with success to GET :show" do
      get :show, :id => 'a1b2c3', :format => :js
      assigns(:site).should == mock_site
      response.should be_success
    end
    
    it "should respond with success to GET :new" do
      logged_in_user.stub_chain(:sites, :build) { mock_site }
      get :new
      response.should be_success
    end
    
    it "should respond with success to GET :edit" do
      get :edit, :id => 'a1b2c3', :format => :js
      assigns(:site).should == mock_site
      response.should be_success
    end
    
    it "should respond with success to POST :create" do
      logged_in_user.stub_chain(:sites, :build).with({}) { mock_site }
      mock_site.stub(:save) { true }
      mock_site.stub_chain(:delay, :activate) { true }
      
      post :create, :site => {}
      assigns(:site).should == mock_site
      response.should redirect_to(sites_url)
    end
    
    it "should respond with success to PUT :update" do
      mock_site.stub(:update_attributes).with({}) { true }
      mock_site.stub_chain(:delay, :activate) { true }
      
      put :update, :id => 'a1b2c3', :site => {}
      assigns(:site).should == mock_site
      response.should redirect_to(sites_url)
    end
    
    it "should respond with success to DELETE :destroy and archive site" do
      mock_site.stub(:archive)
      delete :destroy, :id => 'a1b2c3'
      assigns(:site).should == mock_site
      response.should redirect_to(sites_url)
    end
    
    it "should respond with success to GET :state when cdn_up_to_date? is false" do
      mock_site.stub(:cdn_up_to_date?).and_return(false)
      get :state, :id => 'a1b2c3', :format => :js
      assigns(:site).should == mock_site
      response.should be_success
    end
    
    it "should respond with success to GET :state when cdn_up_to_date? is true" do
      mock_site.stub(:cdn_up_to_date?).and_return(true)
      get :state, :id => 'a1b2c3', :format => :js
      assigns(:site).should == mock_site
      response.should be_success
    end
  end
  
  context "with suspended logged in user" do
    before(:each) { sign_in :user, logged_in_user(:state => "suspended") }
    
    it "should respond with success to GET :index" do
      get :index
      response.should redirect_to(page_path("suspended"))
    end
    it "should respond with success to GET :show" do
      get :show, :id => 'a1b2c3'
      response.should redirect_to(page_path("suspended"))
    end
    it "should respond with success to GET :new" do
      get :new
      response.should redirect_to(page_path("suspended"))
    end
    it "should respond with success to GET :edit" do
      get :edit, :id => 'a1b2c3'
      response.should redirect_to(page_path("suspended"))
    end
    it "should respond with success to GET :state" do
      get :state, :id => 'a1b2c3'
      response.should redirect_to(page_path("suspended"))
    end
    it "should respond with success to POST :create" do
      post :create, :site => {}
      response.should redirect_to(page_path("suspended"))
    end
    it "should respond with success to PUT :update" do
      put :update, :id => 'a1b2c3', :site => {}
      response.should redirect_to(page_path("suspended"))
    end
    it "should respond with success to DELETE :destroy" do
      delete :destroy, :id => 'a1b2c3'
      response.should redirect_to(page_path("suspended"))
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :show" do
      get :show, :id => 'a1b2c3'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :edit" do
      get :edit, :id => 'a1b2c3'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :state" do
      get :state, :id => 'a1b2c3'
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :site => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => 'a1b2c3', :site => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to DELETE :destroy" do
      delete :destroy, :id => 'a1b2c3'
      response.should redirect_to(new_user_session_path)
    end
  end
  
end