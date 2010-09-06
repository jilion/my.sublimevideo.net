require 'spec_helper'

describe Admin::SitesController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true)
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with success to GET :index" do
      Site.stub(:includes).and_return([])
      get :index
      response.should be_success
    end
    
    it "should respond with success to GET :show" do
      Site.stub_chain(:includes, :find).with('1').and_return(mock_site)
      get :show, :id => '1'
      response.should be_success
    end
    
    it "should respond with success to GET :edit" do
      Site.stub_chain(:includes, :find).with('1').and_return(mock_site)
      get :edit, :id => '1'
      response.should be_success
    end
    
    it "should respond with redirect to successful PUT :update" do
      Site.stub(:find).with("1").and_return(mock_site)
      mock_site.stub(:player_mode=).and_return(true)
      mock_site.stub(:save).and_return(true)
      mock_site.stub(:deactivate)
      mock_site.stub_chain(:delay, :activate).and_return(true)
      put :update, :id => '1', :site => {}
      response.should redirect_to(admin_site_url(mock_site))
    end
    
    it "should respond with success to failing PUT :update" do
      Site.stub(:find).with("1").and_return(mock_site)
      mock_site.stub(:player_mode=).and_return(true)
      mock_site.stub(:save).and_return(false)
      put :update, :id => '1', :site => {}
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
    it "should respond with redirect to GET :edit" do
      get :edit, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1', :site => {}
      response.should redirect_to(new_admin_session_path)
    end
  end
  
private
  
  def mock_site(stubs={})
    @mock_site ||= mock_model(Site, stubs)
  end
  
end