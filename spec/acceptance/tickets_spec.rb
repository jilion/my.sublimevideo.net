require File.dirname(__FILE__) + '/acceptance_helper'

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
    select "I have a request", :from => "ticket_type"
    fill_in "Subject", :with => "I have a request!"
    fill_in "Description", :with => "I have a request this is a long text!"
    click_button "Send"
    
    page.should have_content "Your message has been submitted."
    
    Delayed::Job.last.name.should == 'Ticket#post_ticket'
    VCR.use_cassette("ticket/post_ticket") { Delayed::Worker.new(:quiet => true).work_off }
    Delayed::Job.last.should be_nil
    @current_user.reload.zendesk_id.should be_present
  end
  
  scenario "submit an invalid ticket" do
    select "Choose a category", :from => "ticket_type"
    fill_in "Subject", :with => "I have a request!"
    fill_in "Description", :with => "I have a request this is a long text!"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/feedback)
    Delayed::Job.last.should be_nil
  end
  
  scenario "submit an invalid ticket" do
    select "I have a request", :from => "ticket_type"
    fill_in "Subject", :with => ""
    fill_in "Description", :with => "I have a request this is a long text!"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/feedback)
    Delayed::Job.last.should be_nil
  end
  
  scenario "submit an invalid ticket" do
    select "I have a request", :from => "ticket_type"
    fill_in "Subject", :with => "I have a request!"
    fill_in "Description", :with => ""
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/feedback)
    Delayed::Job.last.should be_nil
  end
  
end