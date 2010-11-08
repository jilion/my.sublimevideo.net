require 'spec_helper'

describe Admin::SitesController do
  
  context "with logged in admin" do
    before(:each) do
      sign_in :admin, logged_in_admin
      Site.stub(:find).with("1") { mock_site }
    end
    
    it "should respond with success to GET :index" do
      get :index
      response.should be_success
    end
    
    it "should respond with success to GET :edit" do
      Site.stub_chain(:includes, :find).with('1') { mock_site }
      
      get :edit, :id => '1'
      response.should be_success
    end
    
    describe "PUT :update" do
      it "should respond with redirect to successful PUT :update" do
        mock_site.stub(:player_mode=).and_return(true)
        mock_site.stub(:save).and_return(true)
        mock_site.stub_chain(:delay, :activate).and_return(true)
        
        put :update, :id => '1', :site => {}
        response.should redirect_to(admin_sites_url)
      end
      
      it "should respond with success to failing PUT :update" do
        mock_site.stub(:player_mode=).and_return(true)
        mock_site.stub(:save).and_return(false)
        
        put :update, :id => '1', :site => {}
        response.should be_success
      end
    end
  end
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :edit" do
      get :edit, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1', :site => {}
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :edit" do
      get :edit, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1', :site => {}
      response.should redirect_to(new_admin_session_path)
    end
  end
  
end