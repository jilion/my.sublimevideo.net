require File.dirname(__FILE__) + '/acceptance_helper'

feature "Sites actions:" do
  
  background do
    sign_in_as_user
  end
  
  scenario "add a new site" do
    visit "/sites"
    fill_in "Hostname", :with => "google.com"
    click_button "Add"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')
    
    site = @current_user.sites.last
    site.hostname.should == "google.com"
    site.license.read.should include(site.licenses_hashes)
  end
  
end