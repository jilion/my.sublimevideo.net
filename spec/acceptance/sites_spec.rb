require 'spec_helper'

feature "Sites actions:" do

  background do
    sign_in_as :user
  end

  scenario "add a new site" do
    # visit "/sites"
    click_link "Add a site"

    fill_in "Domain", :with => "google.com"
    choose "plan_dev"
    click_button "Create"

    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')

    @worker.work_off
    site = @current_user.sites.last
    site.hostname.should == "google.com"
    site.loader.read.should include(site.token)
    site.license.read.should include(site.template_hostnames)
  end

  pending "add a new site with credit card data"

  scenario "edit a site" do
    site = Factory(:site, :user => @current_user, :hostname => 'google.com')

    visit "/sites"
    page.should have_content('google.com')
    click_link "Edit google.com"
    fill_in "Development domains", :with => "google.local"
    click_button "Update settings"

    fill_in "Password", :with => "123456"
    click_button "Done"

    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')

    site = @current_user.sites.last
    site.dev_hostnames.should == "google.local"
  end

  scenario "archive a site" do
    site = Factory(:site, :user => @current_user, :hostname => 'google.com')

    visit "/sites"
    page.should have_content('google.com')
    @current_user.sites.last.hostname.should == "google.com"
    VoxcastCDN.stub_chain(:delay, :purge).twice

    click_link "Edit google.com"
    click_button "Delete my site"

    fill_in "Password", :with => "123456"
    click_button "Done"

    page.should_not have_content('google.com')
    @current_user.sites.not_archived.should be_empty
  end

  # FIXME
  scenario "sort buttons displayed only if count of sites > 1" do
    Factory(:site, :user => @current_user, :hostname => 'google.com')
    visit "/sites"

    page.should have_content('google.com')
    page.should have_no_css('div.sorting')
    page.should have_no_css('a.sort')

    Factory(:site, :user => @current_user, :hostname => 'google2.com')
    visit "/sites"

    page.should have_content('google.com')
    page.should have_content('google2.com')
    page.should have_css('div.sorting')
    page.should have_css('a.sort.date')
    page.should have_css('a.sort.hostname')
  end

  # FIXME
  scenario "pagination links displayed only if count of sites > Site.per_page" do
    Responders::PaginatedResponder.stub(:per_page).and_return(1)
    Factory(:site, :user => @current_user, :hostname => 'google.com')
    visit "/sites"

    page.should have_no_content('Next')
    page.should have_no_css('nav.pagination')
    page.should have_no_css('span.next')

    Factory(:site, :user => @current_user, :hostname => 'google2.com')
    visit "/sites"

    page.should have_css('nav.pagination')
    page.should have_css('span.prev')
    page.should have_css('em.current')
    page.should have_css('a.next')
  end

  scenario "user suspended" do
    @current_user.suspend
    visit "/sites"

    current_url.should =~ %r(http://[^/]+/suspended)
  end

end