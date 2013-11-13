require 'spec_helper'

feature "Mail templates" do

  background do
    sign_in_as :admin, roles: ['god']
    create(:user)
  end

  scenario "it is possible to edit a mail template" do
    mail_template = create(:mail_template)
    expect(MailTemplate.count).to eq(1)

    go 'admin', "mails/templates/#{mail_template.id}/edit"

    expect(page).to have_content(mail_template.title)
    expect(page).to have_content "John Doe (#{User.first.email}), help us shaping the right pricing"
    expect(page).to have_content "Please respond to the survey, by clicking on the following url: http://survey.com"

    fill_in "Title",   with: "This is a title"
    fill_in "Subject", with: "This is a subject"
    fill_in "Body",    with: "This is a body"
    click_button "Update mail template"

    expect(page).to have_content "Mail template has been successfully updated."
    expect(page).to have_content "This is a title"
    expect(page).to have_content "This is a subject"
    expect(page).to have_content "This is a body"
  end

end
