require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Mails index:" do
  background do
    sign_in_as :admin
  end
  
  scenario "should have a table containing mail templates" do
    mail_template = Factory(:mail_template)
    # mail_log = Factory(:mail_log)
    Mail::Template.all.size.should == 1
    # MailLog.all.size.should == 1
    
    visit "/admin/mails"
    
    # page.should have_css('div#mail_logs_table_wrap')
    # page.should have_css('tr')
    # page.should have_content(mail_log.title)
    # page.should have_content(mail_log.subject)
    # page.should have_content(truncate(mail_log.body))
    
    page.should have_css('div#mail_templates_table_wrap')
    page.should have_css('tr')
    
    page.should have_content(mail_template.title)
    page.should have_content(mail_template.subject)
    page.should have_content("Hi {{user.full_name}},")
  end
end