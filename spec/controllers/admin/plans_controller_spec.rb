require 'spec_helper'

describe Admin::PlansController do
  
  context "with logged in admin" do
    before :each do
      sign_in :admin, authenticated_admin
    end
    
    it "should respond with success to GET :index" do
      get :index
      response.should be_success
      response.should render_template(:index)
    end
  end
  
  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { :get => :index }
  
end