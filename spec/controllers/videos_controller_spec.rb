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
      @mock_user.stub_chain(:videos, :includes, :where, :by_date).and_return([])
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
      @mock_user.stub_chain(:videos, :build).and_return(mock_video)
      mock_video.stub(:panda_video_id=).with('abcdef123456')
      mock_video.stub(:save).and_return(true)
      mock_video.stub_chain(:delay, :pandize).and_return(true)
      post :create, :video => { :panda_video_id => "abcdef123456" }
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
      mock_video.stub(:archive)
      delete :destroy, :id => '1'
      response.should redirect_to(videos_path)
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
    it "should respond with success to DELETE :destroy" do
      delete :destroy, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
    it "should activate a video and respond with success to GET :transcoded" do
      VideoEncoding.stub(:find_by_panda_encoding_id!).with("a"*32).and_return(mock_video_encoding)
      mock_video_encoding.stub_chain(:delay, :activate).and_return(true)
      get :transcoded, :id => "a"*32
      response.should be_success
    end
  end
  
private
  
  def mock_video(stubs={})
    @mock_video ||= mock_model(Video, stubs)
  end
  
  def mock_video_encoding(stubs={})
    @mock_video_encoding ||= mock_model(VideoEncoding, stubs)
  end
  
end