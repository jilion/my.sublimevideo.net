require File.dirname(__FILE__) + '/../../acceptance_helper'

feature "Mail logs index:" do
  background do
    sign_in_as :admin
    Factory(:user)
  end
  
  pending "should be possible to show mail log" do
    mail_log = Factory(:mail_log)
    Mail::Log.all.size.should == 1
    
    visit "/admin/mails/logs/#{mail_log.id}"
    
    page.should have_content(mail_log.admin.email)
    page.should have_content(mail_log.template.title)
  end
end