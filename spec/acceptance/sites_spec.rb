require File.dirname(__FILE__) + '/acceptance_helper'

feature "Sites actions:" do
  
  background do
    sign_in_as_user
  end
  
  scenario "add a new site" do
    visit "/sites"
    fill_in "Domain", :with => "google.com"
    click_button "Add"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')
    
    Delayed::Job.last.name.should == 'Site#activate'
    Delayed::Worker.new.work_off
    
    site = @current_user.sites.last
    site.hostname.should == "google.com"
    site.loader.read.should include(site.token)
    site.license.read.should include(site.template_hostnames)
  end
  
  scenario "sort buttons displayed only if count of sites > 1" do
    visit "/sites"
    fill_in "Domain", :with => "google.com"
    click_button "Add"
    
    page.should have_content('google.com')
    page.should have_no_css('div.sorting')
    page.should have_no_css('a.sort')
    
    fill_in "Domain", :with => "remy.me" # one day it'll be mine!
    click_button "Add"
    
    page.should have_content('google.com')
    page.should have_content('remy.me')
    page.should have_css('div.sorting')
    page.should have_css('a.sort.date')
    page.should have_css('a.sort.hostname')
  end
  
end