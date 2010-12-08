require 'spec_helper'

describe Admin::SitesController do
  
  context "with logged in admin" do
    before :each do
      sign_in :admin, authenticated_admin
    end
    
    it "should respond with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end
    
    it "should respond with redirect to GET :show" do
      get :show, :id => 'abc123'
      response.should redirect_to(edit_admin_site_url('abc123'))
    end
    
    it "should respond with success to GET :edit" do
      Site.stub_chain(:includes, :find_by_token).with('abc123') { mock_site }
      
      get :edit, :id => 'abc123'
      response.should be_success
      response.should render_template(:edit)
    end
    
    describe "PUT :update" do
      before(:each) do
        Site.stub(:find_by_token).with('abc123') { mock_site }
      end
      
      it "should respond with redirect to successful PUT :update" do
        mock_site.stub(:player_mode=) { true }
        mock_site.stub(:save) { true }
        
        put :update, :id => 'abc123', :site => {}
        response.should redirect_to(admin_sites_url)
      end
      
      it "should respond with success to failing PUT :update" do
        mock_site.stub(:player_mode=) { true }
        mock_site.stub(:save) { false }
        mock_site.should_receive(:errors).any_number_of_times.and_return(["error"])
        
        put :update, :id => 'abc123', :site => {}
        response.should be_success
        response.should render_template(:edit)
      end
    end
  end
  
  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { :get => [:index, :edit], :put => :update }
  
end