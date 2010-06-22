require 'spec_helper'

describe Admin::VideoProfileVersionsController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true)
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with success to GET :index" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      mock_profile.stub_chain(:versions, :order).and_return([])
      get :index, :profile_id => '1'
      response.should be_success
    end
    it "should respond with success to GET :show" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      mock_profile.stub_chain(:versions, :find).with('2').and_return(mock_version)
      mock_version.stub(:panda_profile_id).and_return('3')
      Transcoder.stub(:get).with('3').and_return({})
      VCR.use_cassette('video_profile_version/show') { get :show, :profile_id => '1', :id => '2' }
      response.should be_success
    end
    it "should respond with success to GET :new" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      mock_profile.stub_chain(:versions, :build).and_return(mock_version)
      get :new, :profile_id => '1'
      response.should be_success
    end
    it "should respond with success to POST :create" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      mock_profile.stub_chain(:versions, :build).with({}).and_return(mock_version)
      mock_version.stub(:pandize).and_return(true)
      post :create, :profile_id => '1', :video_profile_version => {}
      response.should redirect_to(admin_profile_versions_url(mock_profile))
    end
    it "should respond with success to PUT :update" do
      VideoProfile.stub(:find).with("1").and_return(mock_profile)
      mock_profile.stub_chain(:versions, :find).with('2').and_return(mock_version)
      mock_version.stub(:activate).and_return(true)
      put :update, :profile_id => '1', :id => '2'
      response.should redirect_to(admin_profile_versions_url(mock_profile))
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index, :profile_id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :show" do
      get :show, :profile_id => '1', :id => '2'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :new" do
      get :new, :profile_id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :profile_id => '1', :video_profile_version => {}
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      post :create, :profile_id => '1', :id => '2'
      response.should redirect_to(new_admin_session_path)
    end
  end
  
private
  
  def mock_profile(stubs={})
    @mock_profile ||= mock_model(VideoProfile, stubs)
  end
  
  def mock_version(stubs={})
    @mock_version ||= mock_model(VideoProfileVersion, stubs)
  end
  
end