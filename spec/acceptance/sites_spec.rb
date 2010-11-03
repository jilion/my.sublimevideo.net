require 'spec_helper'

feature "Sites actions:" do
  before(:all) do
    # move this somewhere else and DRY it with the populate
    plans = [
      { :name => "perso_year",       :term_type => "year",  :player_hits => 3000,   :price => 2990,  :overage_price => 299 },
      { :name => "pro_month",        :term_type => "month", :player_hits => 30000,  :price => 999,   :overage_price => 199 },
      { :name => "pro_year",         :term_type => "year",  :player_hits => 30000,  :price => 9990,  :overage_price => 199 },
      { :name => "enterprise_month", :term_type => "month", :player_hits => 300000, :price => 4999,  :overage_price => 99 },
      { :name => "enterprise_year",  :term_type => "year",  :player_hits => 300000, :price => 49990, :overage_price => 99 }
    ]
    plans.each { |attributes| Plan.create(attributes) }
  end
  
  background do
    sign_in_as :user
  end
  
  scenario "create a new site" do
    create_site
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')
    
    # Delayed::Job.last.name.should == 'Site#activate'
    # Delayed::Worker.new(:quiet => true).work_off
    
    site = @current_user.sites.last
    site.hostname.should == "google.com"
    # site.loader.read.should include(site.token)
    # site.license.read.should include(site.template_hostnames)
  end
  
  # Capybara JS not compatible with special onclick (I suppose)
  pending "edit a site" do
    VCR.use_cassette('acceptance/sites/edit') do
      Capybara.default_wait_time = 5
      Capybara.current_driver = :akephalos
      
      site = Factory(:site, :user => @current_user, :hostname => 'google.com', :state => 'active')
      visit "/sites"
      
      page.should have_content('google.com')
      
      within(:css, "tr#site_#{site.id}") do
        click_link "Settings"
      end
      find_button('Update') # wait for button
      
      fill_in "Alias domains", :with => "google.ch, google.fr"
      fill_in "Development domains", :with => "google.local, localhost"
      click_button "Update"
      
      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content('google.com')
      
      site = @current_user.sites.last
      site.dev_hostnames.should == "google.local"
    end
  end
  
  pending "archive a pending site" do
    create_site
    
    page.should have_content('google.com')
    @current_user.sites.last.hostname.should == "google.com"
    VoxcastCDN.stub_chain(:delay, :purge).twice
    
    click_button "Delete"
    
    page.should_not have_content('google.com')
    @current_user.sites.not_archived.should be_empty
  end
  
  scenario "sort buttons displayed only if count of sites > 1" do
    create_site
    visit "/sites"
    page.should have_content('google.com')
    page.should have_no_css('div.sorting')
    page.should have_no_css('a.sort')
    
    create_site "remy.me"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')
    page.should have_content('remy.me')
    page.should have_css('div.sorting')
    page.should have_css('a.sort.date')
    page.should have_css('a.sort.hostname')
  end
  
  scenario "pagination links displayed only if count of sites > Site.per_page" do
    Site.stub!(:per_page).and_return(1)
    create_site
    
    page.should have_no_content('Next')
    page.should have_no_css('div.pagination')
    page.should have_no_css('span.next_page')
    
    create_site "remy.me"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_css('div.pagination')
    page.should have_css('span.previous_page')
    page.should have_css('em.current_page')
    page.should have_css('a.next_page')
  end
  
  scenario "user suspended" do
    @current_user.suspend
    visit "/sites"
    
    current_url.should =~ %r(http://[^/]+/suspended)
  end
  
end

def create_site(hostname = 'google.com')
  visit "/sites/new"
  fill_in "site_hostname", :with => hostname
  choose "plan_id_pro_month"
  
  if page.has_css?('#site_user_attributes_cc_full_name')#!@current_user.cc? || @current_user.cc_expired?
    VCR.use_cassette('credit_card_visa_validation') do
      fill_in "site_user_attributes_cc_full_name", :with => "John Doe"
      fill_in "site_user_attributes_cc_number", :with => "4111111111111111"
      fill_in "site_user_attributes_cc_verification_value", :with => "111"
      click_button "Add"
    end
  else
    click_button "Add"
  end
end