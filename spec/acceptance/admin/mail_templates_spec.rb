require 'spec_helper'

feature "Mail templates index:" do
  background do
    sign_in_as :admin
    Factory(:user)
  end
  
  scenario "should be possible to edit mail template" do
    mail_template = Factory(:mail_template)
    MailTemplate.all.size.should == 1
    
    visit "/admin/mails/templates/#{mail_template.id}/edit"
    
    page.should have_content(mail_template.title)
    page.should have_content("John Doe (#{User.first.email}), help us shaping the right pricing")
    
    "Hi John Doe (#{User.first.email}), please respond to the survey, by clicking on the following link:\nhttp://survey.com".split("\n").each do |body_parts|
      page.should have_content(body_parts)
    end
    
    fill_in "Title",   :with => "This is a title"
    fill_in "Subject", :with => "This is a subject"
    fill_in "Body",    :with => "This is a body"
    click_button "Update mail template"
    
    page.should have_content "Template was successfully updated."
    page.should have_content "This is a title"
    page.should have_content "This is a subject"
    page.should have_content "This is a body"
  end
end