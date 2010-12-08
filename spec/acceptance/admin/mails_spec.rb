require 'spec_helper'

describe "Mails" do
  before(:all) { @worker = Delayed::Worker.new }
  
  feature "Mails index with no logs and no templates" do
    background do
      sign_in_as :admin
    end
    
    scenario "should be 0 template and 0 log created" do
      MailTemplate.all.size.should == 0
      MailLog.all.size.should == 0
    end
    
    scenario "should have text instead of tables if no templates or no logs exist" do
      visit "/admin/mails"
      
      page.should have_css('div#mail_logs_table_wrap')
      page.should have_no_css('table#mail_logs')
      page.should have_css('div#mail_templates_table_wrap')
      page.should have_no_css('table#mail_templates')
      
      page.should have_content("No mail sent yet!")
      page.should have_content("No mail templates yet!")
    end
  end
  
  feature "Mails index with logs and templates" do
    background do
      @admin = sign_in_as :admin
      @mail_log      = Factory(:mail_log)
      @mail_template = @mail_log.template
    end
    
    scenario "should be 1 template and 1 log created" do
      MailTemplate.all.size.should == 1
      MailLog.all.size.should == 1
    end
    
    scenario "should have a table containing mail logs and a table containing mail templates" do
      visit "/admin/mails"
      
      page.should have_css('div#mail_logs_table_wrap')
      page.should have_css('table#mail_logs')
      
      page.should have_css('div#mail_templates_table_wrap')
      page.should have_css('table#mail_templates')
      
      page.should have_content(@mail_log.admin.email)
      page.should have_content(@mail_log.template.title)
      page.should have_content(@mail_log.user_ids.size.to_s)
      
      page.should have_content(@mail_template.title)
      page.should have_content(@mail_template.subject)
      page.should have_content("Hi {{user.full_name}}")
    end
  end
  
  feature "Mails sending" do
    background do
      @user = Factory(:user)
      @admin = sign_in_as :admin
      @mail_template = Factory(:mail_template)
    end
    
    # context "choosing 'with activity' criteria" do
    #   background do
    #     User.stub_chain(:with_activity).and_return { [@user] }
    #     ActionMailer::Base.deliveries.clear
    #   end
    #   
    #   scenario "should be possible to send an email from a template to a selection of users" do
    #     visit "/admin/mails/new"
    #     
    #     page.should have_content("Send a mail")
    #     ActionMailer::Base.deliveries.should be_empty
    #     
    #     select @mail_template.title, :from => "Template"
    #     select "with activity", :from => "Criteria"
    #     click_button "Send mail"
    #     
    #     current_url.should =~ %r(http://[^/]+/admin/mails)
    #     
    #     page.should have_content("Sending in progress...")
    #     
    #     Delayed::Job.where(:handler.matches => "%deliver_and_log%").count.should == 1
    #     lambda { @worker.work_off }.should change(ActionMailer::Base.deliveries, :count).by(1)
    #     
    #     latest_log = MailLog.by_date.first
    #     latest_log.template_id.should == @mail_template.id
    #     latest_log.admin_id.should == @admin.id
    #     latest_log.snapshot.should == @mail_template.snapshotize
    #     latest_log.criteria.should == "with_activity"
    #   end
    # end
    
    context "choosing 'with invalid site' criteria" do
      let(:user_with_invalid_site) { Factory(:user, :invitation_token => nil) }
      background do
        @invalid_site = Factory.build(:site, :user => user_with_invalid_site, :hostname => 'test')
        @invalid_site.save(:validate => false)
        ActionMailer::Base.deliveries.clear
      end
      
      scenario "should be possible to send an email from a template to a selection of users" do
        visit "/admin/mails/new"
        
        page.should have_content("Send a mail")
        ActionMailer::Base.deliveries.should be_empty
        
        select @mail_template.title, :from => "Template"
        select "with invalid site", :from => "Criteria"
        click_button "Send mail"
        
        current_url.should =~ %r(http://[^/]+/admin/mails)
        
        page.should have_content("Sending in progress...")
        
        Delayed::Job.where(:handler.matches => "%deliver_and_log%").count.should == 1
        lambda { @worker.work_off }.should change(ActionMailer::Base.deliveries, :count).by(1)
        
        latest_log = MailLog.by_date.first
        latest_log.template_id.should == @mail_template.id
        latest_log.admin_id.should == @admin.id
        latest_log.snapshot.should == @mail_template.snapshotize
        latest_log.criteria.should == "with_invalid_site"
      end
    end
  end
  
end