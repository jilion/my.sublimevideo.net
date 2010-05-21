require 'spec_helper'

describe VideosController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before(:each) do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with success to GET :index" do
      @mock_user.stub_chain(:videos, :includes, :by_date).and_return([])
      get :index
      response.should be_success
    end
    it "should respond with success to GET :show" do
      @mock_user.stub_chain(:videos, :find).with("1").and_return(mock_video)
      get :show, :id => '1'
      response.should be_success
    end
    it "should respond with success to GET :edit" do
      @mock_user.stub_chain(:videos, :find).with("1").and_return(mock_video)
      get :edit, :id => '1'
      response.should be_success
    end
    it "should respond with success to POST :create" do
      @mock_user.stub_chain(:videos, :build).with({}).and_return(mock_video)
      mock_video.stub(:save).and_return(true)
      post :create, :video => {}
      response.should redirect_to(videos_url)
    end
    it "should respond with success to PUT :update" do
      @mock_user.stub_chain(:videos, :find).with("1").and_return(mock_video)
      mock_video.stub(:update_attributes).with({}).and_return(true)
      put :update, :id => '1', :video => {}
      response.should redirect_to(videos_url)
    end
    it "should respond with success to DELETE :destroy" do
      @mock_user.stub_chain(:videos, :find).with("1").and_return(mock_video)
      mock_video.stub(:destroy)
      delete :destroy, :id => '1'
      response.should be_success
    end
    it "should respond with success to GET :transcoded" do
      @mock_user.stub_chain(:videos, :find_by_panda_id).with("1").and_return(mock_video)
      mock_video.stub(:activate)
      get :transcoded, :id => '1'
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
      post :create, :video => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with success to PUT :update" do
      put :update, :id => '1', :video => {}
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with success to DELETE :destoy" do
      delete :destroy, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
  end
  
private
  
  def mock_video(stubs={})
    @mock_video ||= mock_model(Video, stubs)
  end
  
end