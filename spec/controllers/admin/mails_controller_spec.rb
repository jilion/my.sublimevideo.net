require 'spec_helper'

describe Admin::MailsController do
  include Devise::TestHelpers
  
  # context "with logged in admin" do
  #   before :each do
  #     mock_admin = Factory(:admin)
  #     mock_admin.stub!(:confirmed? => true)
  #     sign_in :admin, mock_admin
  #   end
  #   
  #   describe "show log" do
  #     it "should respond with success to GET :show" do
  #       Mail::Log.stub(:find).with("1").and_return(mock_mail_log)
  #       get :show, :id => '1'
  #       response.should be_success
  #     end
  #   end
  # end
  # 
  # context "with logged in user" do
  #   before :each do
  #     mock_user = Factory(:user)
  #     mock_user.stub!(:active? => true, :confirmed? => true)
  #     sign_in :user, mock_user
  #   end
  #   
  #   describe "show log" do
  #     it "should respond with redirect to GET :show" do
  #       get :show, :id => '1'
  #       response.should redirect_to(new_admin_session_path)
  #     end
  #   end
  # end
  # 
  # context "as guest" do
  #   describe "show log" do
  #     it "should respond with redirect to GET :show" do
  #       get :show, :id => '1'
  #       response.should redirect_to(new_admin_session_path)
  #     end
  #   end
  # end
  
private
  
  def mock_mail_log(stubs={})
    @mock_mail_log ||= mock_model(Mail::Log, stubs)
  end
  
end