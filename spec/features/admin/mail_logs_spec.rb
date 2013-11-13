require 'spec_helper'

feature "Mail logs show:" do
  background do
    sign_in_as :admin, roles: ['god']
    @mail_log = create(:mail_log)
    create(:user)
  end

  scenario "should be possible to show mail log" do
    go 'admin', "mails/logs/#{@mail_log.id}"

    expect(page).to have_content(@mail_log.admin.email)
    expect(page).to have_content(@mail_log.template.title)
    expect(page).to have_content(@mail_log.template.subject)

    expect(page).to have_content "Please respond to the survey, by clicking on the following url: http://survey.com"

    expect(page).to have_content(@mail_log.admin_id.to_s)
    expect(page).to have_content(@mail_log.template_id.to_s)
    expect(page).to have_content(@mail_log.criteria.inspect)
  end

end
