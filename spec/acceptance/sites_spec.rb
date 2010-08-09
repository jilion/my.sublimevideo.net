require File.dirname(__FILE__) + '/acceptance_helper'

feature "Sites actions:" do
  
  background do
    sign_in_as :user
  end
  
  scenario "add a new site" do
    visit "/sites"
    fill_in "Domain", :with => "google.com"
    click_button "Add"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')
    
    Delayed::Job.last.name.should == 'Site#activate'
    Delayed::Worker.new(:quiet => true).work_off
    
    site = @current_user.sites.last
    site.hostname.should == "google.com"
    site.loader.read.should include(site.token)
    site.license.read.should include(site.template_hostnames)
  end
  
  # scenario "edit a site" do
  #   visit "/sites"
  #   fill_in "Domain", :with => "google.com"
  #   click_button "Add"
  #   
  #   page.should have_content('google.com')
  #   
  #   Delayed::Job.last.name.should == 'Site#activate'
  #   Delayed::Worker.new(:quiet => true).work_off
  #   
  #   click_link "Setting"
  #   fill_in "Development domains", :with => "google.local"
  #   click_button "Update"
  #   
  #   current_url.should =~ %r(http://[^/]+/sites)
  #   page.should have_content('google.com')
  #   
  #   site = @current_user.sites.last
  #   site.dev_hostnames.should == "google.local"
  # end
  
  scenario "archive a pending site" do
    visit "/sites"
    fill_in "Domain", :with => "google.com"
    click_button "Add"
    
    page.should have_content('google.com')
    @current_user.sites.last.hostname.should == "google.com"
    VoxcastCDN.should_receive(:purge).twice
    
    click_button "Delete"
    
    page.should_not have_content('google.com')
    @current_user.sites.not_archived.should be_empty
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
  
  scenario "user suspended" do
    @current_user.suspend
    visit "/sites"
    
    current_url.should =~ %r(http://[^/]+/suspended)
  end
  
end