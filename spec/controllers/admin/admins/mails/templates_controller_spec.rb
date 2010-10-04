require 'spec_helper'

describe Admin::Mails::TemplatesController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before :each do
      mock_admin = Factory(:admin)
      mock_admin.stub!(:confirmed? => true)
      sign_in :admin, mock_admin
    end
    
    describe "edit template" do
      it "should respond with success to GET :edit" do
        Mail::Template.stub(:find).with("1").and_return(mock_mail_template)
        get :edit, :id => '1'
        response.should be_success
      end
    end
    
    describe "update template" do
      it "should respond with redirect to PUT :update that succeed" do
        Mail::Template.stub(:find).with("1").and_return(mock_mail_template)
        mock_mail_template.stub(:update_attributes).and_return(true)
        put :update, :id => '1', :mail_template => { :title => 'AAA', :subject => 'BBB', :body => 'CCC' }
        response.should redirect_to(edit_admin_mail_template_path(mock_mail_template.id))
      end
      
      it "should respond with success to PUT :update that failed" do
        Mail::Template.stub(:find).with("1").and_return(mock_mail_template)
        mock_mail_template.stub(:update_attributes).and_return(false)
        put :update, :id => '1', :mail_template => { :title => 'AAA', :subject => 'BBB', :body => 'CCC' }
        response.should be_success
      end
    end
  end
  
  context "with logged in user" do
    before :each do
      mock_user = Factory(:user)
      mock_user.stub!(:active? => true, :confirmed? => true)
      sign_in :user, mock_user
    end
    
    describe "edit mail template" do
      it "should respond with redirect to GET :edit" do
        get :edit, :id => '1'
        response.should redirect_to(new_admin_session_path)
      end
      
      it "should respond with redirect to PUT :update" do
        put :update, :id => '1', :mail_template => { :title => 'AAA', :subject => 'BBB', :body => 'CCC' }
        response.should redirect_to(new_admin_session_path)
      end
    end
  end
  
  context "as guest" do
    describe "invite admin" do
      it "should respond with redirect to GET :edit" do
        get :edit, :id => '1'
        response.should redirect_to(new_admin_session_path)
      end
      
      it "should respond with redirect to PUT :update" do
        put :update, :id => '1', :mail_template => { :title => 'AAA', :subject => 'BBB', :body => 'CCC' }
        response.should redirect_to(new_admin_session_path)
      end
    end
  end
  
private
  
  def mock_mail_template(stubs={})
    @mock_mail_template ||= mock_model(Mail::Template, stubs)
  end
  
end