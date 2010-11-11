require 'spec_helper'

describe Users::PasswordsController do
  
  context "with logged in user" do
    before(:each) { sign_in :user, authenticated_user }
    
    it "should respond with success to POST :validate" do
      @current_user.stub(:valid_password?).with("secret") { true }
      
      post :validate, :password => 'secret', :format => :js
      assigns(:valid_password).should be_true
      response.should be_success
      response.should render_template(:validate)
    end
    it "should respond with success to POST :validate" do
      @current_user.stub(:valid_password?).with("wrong_secret") { false }
      
      post :validate, :password => 'wrong_secret', :format => :js
      assigns(:valid_password).should be_false
      response.should be_success
      response.should render_template(:validate)
    end
  end
  
  it_should_behave_like "redirect when connected", '/login', :guest, { :post => :validate }
  
end