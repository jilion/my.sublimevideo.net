require 'spec_helper'

describe SitesController do
  
  context "with logged in user" do
    before :each do
      sign_in :user, authenticated_user
      @current_user.stub_chain(:sites, :find_by_token).with('a1b2c3') { mock_site }
      @current_user.stub_chain(:sites, :find).with('1') { mock_site }
    end
    
    describe "GET :index" do
      before :each do
        @current_user.stub_chain(:sites, :not_archived, :with_plan, :with_addons, :by_date).and_return([mock_site])
        get :index
      end
      
      it "should assign sites array as @sites" do
        assigns(:sites).should == [mock_site]
      end
      
      it "should render :index" do
        response.should render_template(:index)
      end
    end
    
    it "should render :show on GET :show" do
      get :show, :id => 'a1b2c3', :format => :js
      assigns(:site).should == mock_site
      response.should render_template(:show)
    end
    
    it "should render :new on GET :new" do
      @current_user.stub_chain(:sites, :build) { mock_site }
      
      get :new
      response.should render_template(:new)
    end
    
    it "should render :edit on GET :edit" do
      get :edit, :id => 'a1b2c3'
      assigns(:site).should == mock_site
      response.should render_template(:edit)
    end
    
    describe "POST :create" do
      before(:each) { @current_user.stub_chain(:sites, :create).with({}).and_return(mock_site) }
      
      it "should redirect to /sites when create succeeds" do
        post :create, :site => {}
        assigns(:site).should == mock_site
        response.should redirect_to(sites_url)
      end
      
      it "should render :new when fail" do
        mock_site.should_receive(:errors).any_number_of_times.and_return(["error"])
        
        post :create, :site => {}
        assigns(:site).should == mock_site
        response.should render_template(:new)
      end
    end
    
    context "site is not active" do
      before(:each) { mock_site.stub(:active?).and_return(false) }
      
      describe "PUT :update" do
        it "should redirect to /sites when update_attributes succeeds" do
          mock_site.stub(:update_attributes).with({}) { true }
          
          put :update, :site => {}, :id => 'a1b2c3'
          assigns(:site).should == mock_site
          response.should redirect_to(sites_url)
        end
        
        it "should redirect to /sites when update_attributes fails" do
          mock_site.stub(:update_attributes).with({}) { false }
          mock_site.should_receive(:errors).any_number_of_times.and_return(["error"])
          
          put :update, :site => {}, :id => 'a1b2c3'
          assigns(:site).should == mock_site
          response.should render_template(:edit)
        end
      end
      
      it "should redirect to /sites on DELETE :destroy" do
        mock_site.stub(:archive)
        
        delete :destroy, :id => 'a1b2c3'
        assigns(:site).should == mock_site
        response.should redirect_to(sites_url)
      end
    end
    
    context "site is active" do
      before(:each) { mock_site.stub(:active?).and_return(true) }
      
      context "with wrong password" do
        before(:each) { @current_user.stub(:valid_password?).with('abcd').and_return(false) }
        
        describe "PUT :update" do
          it "should redirect to /sites/:token/edit" do
            put :update, :id => 'a1b2c3', :site => {}, :user => { :current_password => 'abcd' }
            assigns(:site).should == mock_site
            response.should redirect_to(edit_site_url(mock_site))
          end
        end
        
        describe "PUT :activate" do
          it "should redirect to /sites/:token/edit" do
            put :activate, :id => 'a1b2c3', :user => { :current_password => 'abcd' }
            assigns(:site).should == mock_site
            response.should redirect_to(edit_site_url(mock_site))
          end
        end
        
        describe "DELETE :destroy" do
          it "should redirect to /sites/:token/edit" do
            delete :destroy, :id => 'a1b2c3', :user => { :current_password => 'abcd' }
            assigns(:site).should == mock_site
            response.should redirect_to(edit_site_url(mock_site))
          end
        end
      end
        
      context "with good password" do
        before(:each) { @current_user.stub(:valid_password?).with('123456').and_return(true) }
        
        describe "PUT :update" do
          it "should redirect to /sites when update_attributes succeeds" do
            mock_site.stub(:update_attributes).with({}) { true }
            
            put :update, :id => 'a1b2c3', :site => {}, :user => { :current_password => '123456' }
            assigns(:site).should == mock_site
            response.should redirect_to(sites_url)
          end
          
          it "should redirect to /sites/:token/edit when update_attributes fails" do
            mock_site.stub(:update_attributes).with({}) { false }
            mock_site.should_receive(:errors).any_number_of_times.and_return(["error"])
            
            put :update, :id => 'a1b2c3', :site => {}, :user => { :current_password => '123456' }
            assigns(:site).should == mock_site
            response.should render_template(:edit)
          end
        end
        
        describe "PUT :activate" do
          it "should redirect to /sites when update_attributes succeeds" do
            mock_site.stub(:activate) { true }
            
            put :activate, :id => 'a1b2c3', :user => { :current_password => '123456' }
            assigns(:site).should == mock_site
            response.should redirect_to(sites_url)
          end
          
          it "should redirect to /sites when update_attributes fails" do
            mock_site.stub(:activate){ false }
            
            put :activate, :id => 'a1b2c3', :user => { :current_password => '123456' }
            assigns(:site).should == mock_site
            response.should redirect_to(sites_url)
          end
        end
        
        describe "DELETE :destroy" do
          before(:each) { mock_site.stub(:archive) }
          
          it "should redirect to /sites" do
            delete :destroy, :id => 'a1b2c3', :user => { :current_password => '123456' }
            assigns(:site).should == mock_site
            response.should redirect_to(sites_url)
          end
        end
      end
    end
    
    describe "GET :state" do
      it "should respond with :ok when cdn_up_to_date? is false" do
        mock_site.stub(:cdn_up_to_date?).and_return(false)
        
        get :state, :id => '1', :format => :js
        assigns(:site).should == mock_site
        response.should be_success
      end
      
      it "should render :state when cdn_up_to_date? is true" do
        mock_site.stub(:cdn_up_to_date?).and_return(true)
        
        get :state, :id => '1', :format => :js
        assigns(:site).should == mock_site
        response.should render_template(:state)
      end
    end
    
    it "should respond with success to GET :usage" do
      get :usage, :id => 'a1b2c3', :format => :js
      
      assigns(:site).should == mock_site
      response.should be_success
    end
  end
  
  verb_and_actions = { :get => [:index, :show, :new, :edit, :state, :usage], :post => :create, :put => :update, :delete => :destroy }
  it_should_behave_like "redirect when connected", '/suspended', [[:user, { :suspended? => true }]], verb_and_actions
  it_should_behave_like "redirect when connected", '/login', [:guest], verb_and_actions
  
end