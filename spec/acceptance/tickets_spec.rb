require 'spec_helper'

feature "Feedback actions:" do
  
  background do
    @current_user = sign_in_as :user
    visit "/feedback"
  end
  
  scenario "navigation" do
    click_link "Feedback"
    current_url.should =~ %r(http://[^/]+/feedback)
  end
  
  scenario "submit a valid ticket" do
    select "Bug report", :from => "ticket_type"
    fill_in "Subject", :with => "I have a request!"
    fill_in "Message", :with => "I have a request this is a long text!"
    click_button "Send"
    
    page.should have_content "Your message has been submitted."
    
    Delayed::Job.last.name.should == 'Ticket#post_ticket'
    VCR.use_cassette("ticket/post_ticket") { Delayed::Worker.new(:quiet => true).work_off }
    Delayed::Job.last.should be_nil
    @current_user.reload.zendesk_id.should be_present
  end
  
  scenario "submit an ticket with an invalid type" do
    select "Choose a category", :from => "ticket_type"
    fill_in "Subject", :with => "I have a request!"
    fill_in "Message", :with => "I have a request this is a long text!"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/feedback)
    page.should have_content "You must choose a category"
    page.should have_no_content "Your message has been submitted."
    Delayed::Job.last.should be_nil
  end
  
  scenario "submit a ticket with an invalid subject" do
    select "Improvement suggestion", :from => "ticket_type"
    fill_in "Subject", :with => ""
    fill_in "Message", :with => "I have a request this is a long text!"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/feedback)
    
    page.should have_content "Subject can't be blank"
    page.should have_no_content "Your message has been submitted."
    Delayed::Job.last.should be_nil
  end
  
  scenario "submit a ticket with an invalid message" do
    select "Feature request", :from => "ticket_type"
    fill_in "Subject", :with => "I have a request!"
    fill_in "Message", :with => ""
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/feedback)
    page.should have_content "Message can't be blank"
    page.should have_no_content "Your message has been submitted."
    Delayed::Job.last.should be_nil
  end
  
end