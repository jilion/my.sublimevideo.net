require 'spec_helper'

describe Admin::MailLogsController do
  
  context "with logged in admin" do
    before(:each) { sign_in :admin, logged_in_admin }
    
    it "should respond with success to GET :show" do
      MailLog.stub(:find).with("1") { mock_mail_log }
      
      get :show, :id => '1'
      response.should be_success
    end
  end
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with redirect to GET :show" do
      get :show, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :show" do
      get :show, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
  end
  
end