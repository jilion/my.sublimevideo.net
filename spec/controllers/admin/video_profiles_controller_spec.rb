require 'spec_helper'

describe Admin::VideoProfilesController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true)
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with success to GET :index" do
      VideoProfile.stub(:includes).and_return([])
      get :index
      response.should be_success
    end
    it "should respond with success to GET :show" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      mock_profile.stub_chain(:versions, :order).and_return([])
      get :show, :id => '1'
      response.should be_success
    end
    it "should respond with success to GET :new" do
      VideoProfile.stub(:new).and_return(mock_profile)
      get :new
      response.should be_success
    end
    it "should respond with success to GET :edit" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      get :edit, :id => '1'
      response.should be_success
    end
    it "should respond with success to POST :create" do
      VideoProfile.stub(:new).with({}).and_return(mock_profile)
      mock_profile.stub(:name=).and_return(mock_profile)
      mock_profile.stub(:extname=).and_return(mock_profile)
      mock_profile.stub(:save).and_return(true)
      post :create, :video_profile => {}
      response.should redirect_to(admin_profiles_url)
    end
    it "should respond with success to PUT :update" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      mock_profile.stub(:update_attributes).with({}).and_return(true)
      put :update, :id => '1', :video_profile => {}
      response.should redirect_to(admin_profiles_url)
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
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :edit" do
      get :edit, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :video_profile => {}
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1', :video_profile => {}
      response.should redirect_to(new_admin_session_path)
    end
  end
  
private
  
  def mock_profile(stubs={})
    @mock_profile ||= mock_model(VideoProfile, stubs)
  end
  
end