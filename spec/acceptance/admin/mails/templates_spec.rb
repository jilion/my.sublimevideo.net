require File.dirname(__FILE__) + '/../../acceptance_helper'

feature "Mail templates index:" do
  background do
    sign_in_as :admin
    Factory(:user)
  end
  
  scenario "should be possible to edit mail template" do
    mail_template = Factory(:mail_template)
    Mail::Template.all.size.should == 1
    
    visit "/admin/mails/templates/#{mail_template.id}/edit"
    
    page.should have_content(mail_template.title)
    page.should have_content(mail_template.subject)
    page.should have_content("Hi John Doe,")
    
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