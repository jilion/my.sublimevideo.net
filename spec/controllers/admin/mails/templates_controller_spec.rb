require 'spec_helper'

describe Admin::Mails::TemplatesController do
  include Devise::TestHelpers
  
  context "with logged in admin" do
    before(:each) do
      sign_in :admin, logged_in_admin
      Mail::Template.stub(:find).with("1").and_return(mock_mail_template)
    end
    
    it "should respond with success to GET :edit" do
      get :edit, :id => '1'
      response.should be_success
    end
    
    describe "PUT :update" do
      it "should respond with redirect to PUT :update that succeed" do
        mock_mail_template.stub(:update_attributes).and_return(true)
        
        put :update, :id => '1', :mail_template => { :title => 'AAA', :subject => 'BBB', :body => 'CCC' }
        response.should redirect_to(edit_admin_mail_template_path(mock_mail_template.id))
      end
      
      it "should respond with success to PUT :update that failed" do
        mock_mail_template.stub(:update_attributes).and_return(false)
        
        put :update, :id => '1', :mail_template => { :title => 'AAA', :subject => 'BBB', :body => 'CCC' }
        response.should be_success
      end
    end
  end
  
  context "with logged in user" do
    before(:each) { sign_in :user, logged_in_user }
    
    it "should respond with redirect to GET :edit" do
      get :edit, :id => '1'
      response.should redirect_to(new_admin_session_path)
    end
    it "should respond with redirect to PUT :update" do
      put :update, :id => '1', :mail_template => { :title => 'AAA', :subject => 'BBB', :body => 'CCC' }
      response.should redirect_to(new_admin_session_path)
    end
  end
  
  context "as guest" do
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