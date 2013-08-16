require 'spec_helper'

feature "Mail templates" do

  background do
    sign_in_as :admin, roles: ['god']
    create(:user)
  end

  scenario "it is possible to edit a mail template" do
    mail_template = create(:mail_template)
    MailTemplate.should have(1).item

    go 'admin', "mails/templates/#{mail_template.id}/edit"

    page.should have_content(mail_template.title)
    page.should have_content "John Doe (#{User.first.email}), help us shaping the right pricing"
    page.should have_content "Please respond to the survey, by clicking on the following url: http://survey.com"

    fill_in "Title",   with: "This is a title"
    fill_in "Subject", with: "This is a subject"
    fill_in "Body",    with: "This is a body"
    click_button "Update mail template"

    page.should have_content "Mail template has been successfully updated."
    page.should have_content "This is a title"
    page.should have_content "This is a subject"
    page.should have_content "This is a body"
  end

end
