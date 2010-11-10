require 'spec_helper'

describe Users::PasswordsController do
  
  context "with logged in user" do
    before(:each) { sign_in :user, authenticated_user }
    
    it "should respond with head ok to POST :validate" do
      @current_user.stub(:valid_password?).with("secret") { true }
      
      post :validate, :password => 'secret'
      response.should be_success
      response.status.should == 200
    end
    it "should respond with head error to POST :validate" do
      @current_user.stub(:valid_password?).with("wrong_secret") { false }
      
      post :validate, :password => 'wrong_secret'
      response.should_not be_success
      response.status.should == 403
    end
  end
  
  it_should_behave_like "redirect when connected", '/login', [:guest], { :post => :validate }
  
end