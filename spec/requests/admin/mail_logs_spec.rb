require 'spec_helper'

feature "Mail logs show:" do

  background do
    sign_in_as :admin, roles: ['god']
    @mail_log = Factory.create(:mail_log)
    Factory.create(:user)
  end

  scenario "should be possible to show mail log" do
    go 'admin', "mails/logs/#{@mail_log.id}"

    page.should have_content(@mail_log.admin.email)
    page.should have_content(@mail_log.template.title)
    page.should have_content(@mail_log.template.subject)

    page.should have_content "Hi {{user.name}} ({{user.email}}), please respond to the survey, by clicking on the following url: http://survey.com"

    page.should have_content(@mail_log.admin_id.to_s)
    page.should have_content(@mail_log.template_id.to_s)
    page.should have_content(@mail_log.criteria.inspect)
  end

end
