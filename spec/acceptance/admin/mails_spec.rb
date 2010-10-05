require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Mails index with no logs and no templates" do
  background do
    sign_in_as :admin
  end
  
  scenario "should be 0 template and 0 log created" do
    Mail::Template.all.size.should == 0
    Mail::Log.all.size.should == 0
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
    Mail::Template.all.size.should == 1
    Mail::Log.all.size.should == 1
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
    page.should have_content("Hi {{user.full_name}},")
  end
end

feature "Mails sending" do
  background do
    @admin = sign_in_as :admin
    @mail_log      = Factory(:mail_log)
    @mail_template = @mail_log.template
    user = Factory(:user)
    User.stub_chain(:with_activity, :all) { [user] }
    ActionMailer::Base.deliveries.clear
  end
  
  scenario "should be possible to send an email from a template to a selection of users" do
    visit "/admin/mails/new"
    
    page.should have_content("Send a mail")
    ActionMailer::Base.deliveries.size.should == 0
    
    select @mail_template.title, :from => "Template"
    select "with activity", :from => "Criteria"
    click_button "Send mail"
    
    last_log = Mail::Log.all.last
    
    current_url.should =~ %r(http://[^/]+/admin/mails)
    page.should have_content("Mail with template '#{@mail_template.title}' will be sent to 1 user!")
    last_log.template_id.should == @mail_template.id
    last_log.admin_id.should == @admin.id
    last_log.snapshot.should == @mail_template.snapshotize
    last_log.criteria.should == "with_activity"
    Delayed::Job.where(:handler.matches => "%deliver%").count.should == 1
    Delayed::Worker.new(:quiet => true).work_off
    ActionMailer::Base.deliveries.size.should == 1
  end
end