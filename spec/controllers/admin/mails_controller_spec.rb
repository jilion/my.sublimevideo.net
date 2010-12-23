require 'spec_helper'

describe Admin::MailsController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before(:each) { sign_in :admin, logged_in_admin }
    
    describe "GET :index" do
      before(:each) do
        Mail::Log.stub_chain(:scoped, :by_date, :paginate) { [mock_mail_log] }
        Mail::Template.stub_chain(:scoped, :by_date, :paginate) { [mock_mail_template] }
        get :index
      end
      
      it "should assign mail logs array as @mail_logs" do
        assigns(:mail_logs).should == [mock_mail_log]
      end
      it "should assign mail templates array as @mail_templates" do
        assigns(:mail_templates).should == [mock_mail_template]
      end
      it "should respond with success" do
        response.should be_success
      end
    end
    
    describe "GET :new" do
      before(:each) do
        Mail::Log.stub(:new) { mock_mail_log }
        get :new
      end
      
      it "should assign mail log as @mail_log" do
        assigns(:mail_log).should be(mock_mail_log)
      end
      it "should respond with success" do
        response.should be_success
      end
    end
    
    describe "POST :create" do
      before(:each) do
        Mail::Letter.stub(:new).with({ "template_id" => '1', "criteria" => "with_activity", "admin_id" => logged_in_admin.id }) { mock_mail_letter }
        mock_mail_letter.stub_chain(:delay, :deliver_and_log) { mock_mail_log }
      end
      
      it "should respond with redirect if create_and_deliver succeed" do
        post :create, :mail_log => { :template_id => '1', :criteria => "with_activity" }
        response.should redirect_to(admin_mails_url)
      end
    end
  end
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
    it "should respond with redirect to GET :index" do
      get :index
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to GET :new" do
      get :new
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to POST :create" do
      post :create
      response.should redirect_to(new_admin_session_path)
    end
  end
  
end