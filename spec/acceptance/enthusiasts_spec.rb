require File.dirname(__FILE__) + '/acceptance_helper'

feature "Enthusiast actions:" do
  
  scenario "register my email for the limited release (aka private beta)!" do
    visit "/"
    current_url.should =~ %r(http://[^/]+/)
    
    fill_in "enthusiast_email",                       :with => "john@doe.com"
    fill_in "enthusiast_sites_attributes_0_hostname", :with => "rymai.com"
    fill_in "enthusiast_free_text",                   :with => "I love U!"
    
    click_button "OK!"
    
    current_url.should =~ %r(http://[^/]+/)
    page.should have_content("Thanks! Please confirm your email, and after that you will be invited for the limited relase.")
    
    Enthusiast.last.email.should == "john@doe.com"
    Enthusiast.last.free_text.should == "I love U!"
    Enthusiast.last.sites.last.hostname.should == "rymai.com"
  end
  
  scenario "confirm my email for the limited release (aka private beta)!" do
    visit "/"
    current_url.should =~ %r(http://[^/]+/)
    
    fill_in "enthusiast_email",                       :with => "john@doe.com"
    fill_in "enthusiast_sites_attributes_0_hostname", :with => "rymai.com"
    fill_in "enthusiast_free_text",                   :with => "I love U!"
    
    click_button "OK!"
    
    current_url.should =~ %r(http://[^/]+/)
    
    visit "/enthusiasts/confirmation?confirmation_token=#{Enthusiast.last.confirmation_token}"
    
    page.should have_content("Your email was successfully confirmed. You will receive an invitation email for the limited release very soon.")
    
    Enthusiast.last.confirmation_token.should be_nil
    Enthusiast.last.confirmation_sent_at.should be_present
    Enthusiast.last.confirmed_at.should be_present
  end
  
end

feature "Logged-in user can't ask for being notified!" do
  
  background do
    sign_in_as_user
  end
  
  scenario "logged-in user should be redirected to /sites" do
    create_user  :user => { :full_name => "John Doe", :email => "john@doe.com", :password => "123456" }
    
    visit "/"
    page.should_not have_content('notify')
    current_url.should =~ %r(http://[^/]+/sites)
  end
  
end