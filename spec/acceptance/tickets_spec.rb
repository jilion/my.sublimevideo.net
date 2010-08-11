require File.dirname(__FILE__) + '/acceptance_helper'

feature "Support actions:" do
  
  background do
    @current_user = sign_in_as :user
  end
  
  scenario "navigation" do
    click_link "Support"
    current_url.should =~ %r(http://[^/]+/support)
  end
  
  scenario "submit a valid ticket" do
    visit "/support"
    
    select "Billing question", :from => "ticket_type"
    fill_in "Subject", :with => "I got a billing problem!"
    fill_in "Description", :with => "I got a billing problem this is a long text!"
    click_button "Send"
    
    page.should have_content "Your message has been submitted."
    
    Delayed::Job.last.name.should == 'Ticket#post_ticket'
    VCR.use_cassette("ticket/post_ticket") { Delayed::Worker.new(:quiet => true).work_off }
    Delayed::Job.last.should be_nil
    @current_user.reload.zendesk_id.should be_present
  end
  
  scenario "submit an invalid ticket" do
    visit "/support"
    
    select "Choose a type for your ticket", :from => "ticket_type"
    fill_in "Subject", :with => "I got a billing problem!"
    fill_in "Description", :with => "I got a billing problem this is a long text!"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/support)
    Delayed::Job.last.should be_nil
  end
  
  scenario "submit an invalid ticket" do
    visit "/support"
    
    select "Billing question", :from => "ticket_type"
    fill_in "Subject", :with => ""
    fill_in "Description", :with => "I got a billing problem this is a long text!"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/support)
    Delayed::Job.last.should be_nil
  end
  
  scenario "submit an invalid ticket" do
    visit "/support"
    
    select "Billing question", :from => "ticket_type"
    fill_in "Subject", :with => "I got a billing problem!"
    fill_in "Description", :with => ""
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/support)
    Delayed::Job.last.should be_nil
  end
  
end