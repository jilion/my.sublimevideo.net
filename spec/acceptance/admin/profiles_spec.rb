require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Profiles actions:" do
  
  background do
    sign_in_as_admin
  end
  
  scenario "add a new profile" do
    visit "/admin/profiles"
    fill_in "Title",       :with => "iPhone 720p"
    fill_in "Description", :with => "A Sublime profile"
    fill_in "Name",        :with => "_iphone_720p"
    fill_in "Extname",     :with => ".mp4"
    check "Thumbnailable"
    click_button "Create"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles)
    
    page.should have_content('iPhone 720p')
    page.should have_content('_iphone_720p')
    page.should have_content('.mp4')
    
    profile = VideoProfile.last
    profile.title.should == "iPhone 720p"
    profile.description.should == "A Sublime profile"
    profile.name.should == "_iphone_720p"
    profile.extname.should == ".mp4"
    profile.thumbnailable.should be_true
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
  # 
  # scenario "sort buttons displayed only if count of sites > 1" do
  #   visit "/sites"
  #   fill_in "Domain", :with => "google.com"
  #   click_button "Add"
  #   
  #   page.should have_content('google.com')
  #   page.should have_no_css('div.sorting')
  #   page.should have_no_css('a.sort')
  #   
  #   fill_in "Domain", :with => "remy.me" # one day it'll be mine!
  #   click_button "Add"
  #   
  #   page.should have_content('google.com')
  #   page.should have_content('remy.me')
  #   page.should have_css('div.sorting')
  #   page.should have_css('a.sort.date')
  #   page.should have_css('a.sort.hostname')
  # end
  
end