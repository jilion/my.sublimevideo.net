require 'spec_helper'

describe Admin::MailsController do
  
  context "with logged in admin" do
    before(:each) { sign_in :admin, authenticated_admin }
    
    it "should assign mail logs array as @mail_logs and mail templates array as @mail_templates and render :index on GET :index" do
      MailLog.stub_chain(:by_date, :paginate) { [mock_mail_log] }
      MailTemplate.stub_chain(:by_date, :paginate) { [mock_mail_template] }
      
      get :index
      assigns(:mail_logs).should == [mock_mail_log]
      assigns(:mail_templates).should == [mock_mail_template]
      response.should be_success
      response.should render_template(:index)
    end
    
    it "should assign mail log as @mail_log and render :new on GET :new" do
      MailLog.stub(:new) { mock_mail_log }
      
      get :new
      assigns(:mail_log).should == mock_mail_log
      response.should be_success
      response.should render_template(:new)
    end
    
    it "should redirect to /admin/mails if create_and_deliver succeed on POST :create" do
      MailLetter.stub(:new).with({ "template_id" => '1', "criteria" => "with_invalid_site", "admin_id" => @current_admin.id }) { mock_mail_letter }
      mock_mail_letter.stub_chain(:delay, :deliver_and_log) { mock_mail_log }
      
      post :create, :mail_log => { :template_id => '1', :criteria => "with_invalid_site" }
      response.should redirect_to(admin_mails_url)
    end
  end
  
  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { :get => [:index, :new], :post => :create }
  
end