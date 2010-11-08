require 'spec_helper'

describe Users::PasswordsController do
  
  context "with logged in user" do
    before :each do
      @mock_user = mock_model(User, :active? => true, :confirmed? => true, :suspended? => false)
      User.stub(:find).and_return(@mock_user)
      sign_in :user, @mock_user
    end
    
    it "should respond with head ok to POST :validate" do
      @mock_user.stub(:valid_password?).with("secret").and_return(true)
      post :validate, :password => 'secret'
      response.should be_success
      response.status.should == 200
    end
    it "should respond with head error to POST :validate" do
      @mock_user.stub(:valid_password?).with("wrong_secret").and_return(false)
      post :validate, :password => 'wrong_secret'
      response.should_not be_success
      response.status.should == 403
    end
  end
  
  context "as guest" do
    it "should respond with redirect to POST :validate" do
      post :validate, :password => 'secret'
      response.should redirect_to(new_user_session_path)
    end
  end
end