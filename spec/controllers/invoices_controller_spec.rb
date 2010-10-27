require 'spec_helper'

describe InvoicesController do
  include Devise::TestHelpers
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    context "public release only", :release => :public do
      it "should respond with success to GET :index" do
        logged_in_user.stub_chain(:invoices, :by_charged_at) { [] }
        
        get :index
        response.should be_success
      end
      
      it "should respond with success to GET :show" do
        logged_in_user.stub_chain(:invoices, :find).with("1") { mock_invoice }
        
        get :show, :id => '1', :format => :js
        response.should be_success
      end
      
      it "should respond with success to GET :show and id == 'current'" do
        Invoice.stub(:current).with(@mock_user) { mock_invoice }
        get :show, :id => 'current', :format => :js
        response.should be_success
      end
    end
    
    context "public release only", :release => :beta do
      it "should respond with redirect to GET :index" do
        get :index
        response.should redirect_to(sites_path)
      end
      it "should respond with redirect to GET :show" do
        get :show, :id => '1'
        response.should redirect_to(sites_path)
      end
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_user_session_path)
    end
    it "should respond with redirect to GET :show" do
      get :show, :id => '1'
      response.should redirect_to(new_user_session_path)
    end
  end
  
end