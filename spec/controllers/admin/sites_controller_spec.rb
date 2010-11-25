require 'spec_helper'

describe Admin::SitesController do
  
  context "with logged in admin" do
    before :each do
      sign_in :admin, authenticated_admin
      Site.stub(:find).with('1') { mock_site }
    end
    
    it "should respond with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end
    
    it "should respond with success to GET :edit" do
      Site.stub_chain(:includes, :find).with('1') { mock_site }
      
      get :edit, :id => '1'
      response.should be_success
      response.should render_template(:edit)
    end
    
    describe "PUT :update" do
      it "should respond with redirect to successful PUT :update" do
        mock_site.stub(:player_mode=) { true }
        mock_site.stub(:save) { true }
        
        put :update, :id => '1', :site => {}
        response.should redirect_to(admin_sites_url)
      end
      
      it "should respond with success to failing PUT :update" do
        mock_site.stub(:player_mode=) { true }
        mock_site.stub(:save) { false }
        mock_site.should_receive(:errors).any_number_of_times.and_return(["error"])
        
        put :update, :id => '1', :site => {}
        response.should be_success
        response.should render_template(:edit)
      end
    end
  end
  
  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { :get => [:index, :edit], :put => :update }
  
end