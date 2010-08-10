require File.dirname(__FILE__) + '/acceptance_helper'

feature "Support actions:" do
  
  background do
    sign_in_as :user
  end
  
  pending "submit a ticket" do
    visit "/support"
    current_url.should =~ %r(http://[^/]+/support)
    
    select "Billing", :from => "ticket_type"
    fill_in "Subject", :with => "I got a billing problem!"
    fill_in "Description", :with => "I got a billing problem this is a long text!"
    click_button "Send"
    
    page.should have_content "Your message has been submitted."
    
    Delayed::Job.last.name.should == 'Ticket#send'
    Delayed::Worker.new(:quiet => true).work_off
    
    @current_user.zendesk_id.should be_present
  end
  
end