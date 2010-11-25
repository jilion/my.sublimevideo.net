require 'spec_helper'

describe Admin::Admins::InvitationsController do
  
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:admin] }
  
  context "with logged in admin" do
    before :each do
      sign_in :admin, authenticated_admin
      Admin.stub(:invite).with({ "email" => 'remy@jilion.com' }) { mock_admin }
    end
    
    it "should respond with success to GET :new" do
      get :new
      response.should be_success
      response.should render_template(:new)
    end
    
    it "should respond with redirect on POST :create that succeeds" do
      mock_admin.stub(:invited?) { true }
      
      post :create, :admin => { :email => 'remy@jilion.com' }
      response.should redirect_to(admin_admins_url)
    end
    
    it "should render :new on POST :create that fails" do
      mock_admin.stub(:invited?) { false }
      
      post :create, :admin => { :email => 'remy@jilion.com' }
      response.should be_success
      response.should render_template(:new)
    end
  end
  
  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { :get => :new, :post => :create }
  
end