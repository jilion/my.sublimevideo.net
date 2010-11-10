require 'spec_helper'

describe Admin::ReleasesController do
  
  context "with logged in admin Zeno" do
    before(:each) do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true, :suspended? => false, :email => "zeno@jilion.com")
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end
    
    describe "POST :create" do
      before(:each) { Release.stub(:new).and_return(mock_release) }
      
      it "should respond with redirect when save succeed" do
        mock_release.stub(:save).and_return(true)
        
        post :create, :release => {}
        response.should redirect_to(admin_releases_path)
      end
      
      it "should respond with success when save fails" do
        mock_release.stub(:save).and_return(false)
        
        post :create, :release => {}
        response.should render_template(:index)
      end
    end
    
    describe "PUT :update" do
      before(:each) { Release.stub(:find).and_return(mock_release) }
      
      it "should respond with redirect when update_attributes succeed" do
        mock_release.stub(:flag).and_return(true)
        
        put :update, :id => "1", :release => {}
        response.should redirect_to(admin_releases_path)
      end
      
      it "should respond with success when update_attributes fails" do
        mock_release.stub(:flag).and_return(false)
        
        put :update, :id => "1", :release => {}
        response.should render_template(:index)
      end
    end
  end
  
  context "with logged in admin" do
    before(:each) do
      @mock_admin = mock_model(Admin, :active? => true, :confirmed? => true, :suspended? => false, :email => "bob@jilion.com")
      Admin.stub(:find).and_return(@mock_admin)
      sign_in :admin, @mock_admin
    end
    
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(admin_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :release => {}
      response.should redirect_to(admin_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => "1", :release => {}
      response.should redirect_to(admin_path)
    end
  end
  
  context "with logged in user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => false)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :release => {}
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => "1", :release => {}
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create, :release => {}
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => "1", :release => {}
      response.should redirect_to(new_admin_session_path)
    end
  end
  
end