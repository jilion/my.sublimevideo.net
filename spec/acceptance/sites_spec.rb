require 'spec_helper'

feature "Sites" do
  before(:all) do
    @worker = Delayed::Worker.new
    # move this somewhere else and DRY it with the populate
    plans = [
      { :name => "perso",      :player_hits => 3000,   :price => 2990, :overage_price => 299 },
      { :name => "pro",        :player_hits => 30000,  :price => 999,  :overage_price => 199 },
      { :name => "enterprise", :player_hits => 300000, :price => 4999, :overage_price => 99 }
    ]
    plans.each { |attributes| Plan.create(attributes) }

    addons = [
      { :name => "ssl", :price => 499 }
    ]
    addons.each { |attributes| Addon.create(attributes) }
  end
  background do
    sign_in_as :user
  end

  # WAITING FOR OCTAVE TO FINISH THE PAGE
  feature "index" do
    pending "sort buttons displayed only if count of sites > 1" do
      create_site
      page.should have_content('rymai.com')
      page.should have_no_css('div.sorting')
      page.should have_no_css('a.sort')

      create_site :hostname => "remy.me"

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content('rymai.com')
      page.should have_content('remy.me')
      page.should have_css('div.sorting')
      page.should have_css('a.sort.date')
      page.should have_css('a.sort.hostname')
    end

    pending "pagination links displayed only if count of sites > Site.per_page" do
      Site.stub!(:per_page).and_return(1)
      create_site

      page.should have_no_content('Next')
      page.should have_no_css('div.pagination')
      page.should have_no_css('span.next_page')

      create_site :hostname => "remy.me"

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_css('div.pagination')
      page.should have_css('span.previous_page')
      page.should have_css('em.current_page')
      page.should have_css('a.next_page')
    end

    pending "user suspended" do
      @current_user.suspend
      visit "/sites"

      current_url.should =~ %r(http://[^/]+/suspended)
    end

    pending "site without an hostname" do
      create_site(:hostname => "")

      page.should have_content('add an hostname')
      page.should have_no_css("#activate_site_#{Site.last.id}")
    end
  end

  scenario "create" do
    create_site

    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('rymai.com')

    @worker.work_off

    site = @current_user.sites.last
    site.hostname.should == "rymai.com"
    site.loader.read.should include(site.token)
    site.license.read.should include(site.template_hostnames)
  end

  pending "transition" do
    create_site
    site = @current_user.sites.last
    # site.stub!(:beta? => true) # fake that the site is in beta state (should not have a plan, but no big deal for this test)
    # @current_user.stub_chain(:sites, :not_archived, :with_plan, :with_addons, :by_date).and_return([site])
    # site.should be_beta
    visit "/sites"
    # within(:css, "tr#site_#{site.id}") do
    #   click_link "Choose a plan"
    # end
    visit "/sites/#{site.token}/transition"
    page.should have_content('Update your site')
    page.should have_content('Unlimited Free Testing on All Plans.')

    fill_in "site_hostname", :with => 'rymai.local' # error!
    click_button "Update"

    # save_and_open_page
    # should render the :transition template, not the :edit template
    # page.should have_content('Unlimited Free Testing on All Plans.') # can't test until I managed to have a site in beta state!!!!
  end

  # WAITING FOR OCTAVE TO FINISH THE PAGE
  feature "edit" do
    background do
      create_site :cdn_up_to_date => true
    end

    pending "edit settings" do
      edit_site_settings :path => '/ipad', :dev_hostnames => 'sjobs.dev, apple.local'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content('apple.com/ipad')
      @current_user.sites.last.dev_hostnames.should == "apple.local, sjobs.dev"
    end

    pending "edit plan" do
      edit_site_plan

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content('Enterprise')
    end

    pending "edit addons" do
      edit_site_addons

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content('Add-ons: Ssl')
    end
  end

  # WAITING FOR OCTAVE TO FINISH THE PAGE
  pending "archive a site" do
    create_site
    visit "/sites/#{@current_user.sites.last.token}/edit"
    VoxcastCDN.stub_chain(:delay, :purge).twice
    click_button "Destroy"

    page.should_not have_content('rymai.com')
    @current_user.sites.last.should be_archived
  end

end

def create_site(*args)
  options = args.extract_options!

  visit "/sites/new"
  fill_in "site_hostname", :with => options[:hostname] || 'rymai.com'
  fill_in "site_extra_hostnames", :with => options[:extra_hostnames] || 'rymai.ch, rymai.fr'
  fill_in "site_dev_hostnames", :with => options[:dev_hostnames] || 'rymai.local'
  fill_in "site_path", :with => options[:path] || '/videos'
  check   "Wildcard"
  choose "plan_id_pro"

  if !@current_user.cc? || @current_user.cc_expired?
    VCR.use_cassette('credit_card_visa_validation') do
      fill_in "site_user_attributes_cc_full_name", :with => "John Doe"
      fill_in "site_user_attributes_cc_number", :with => "4111111111111111"
      fill_in "site_user_attributes_cc_verification_value", :with => "111"
      click_button "Create"
    end
  else
    click_button "Create"
  end
  Site.last.update_attribute(:cdn_up_to_date, true) if options[:cdn_up_to_date]
end

def edit_site_settings(options = {})
  visit_settings(options[:id] || @current_user.sites.last.id)
  fill_in "site_hostname", :with => options[:hostname] || 'apple.com'
  fill_in "site_extra_hostnames", :with => options[:extra_hostnames] || ''
  fill_in "site_dev_hostnames", :with => options[:dev_hostnames] || ''
  fill_in "site_path", :with => options[:path] || ''
  choose "plan_id_enterprise"
  click_button "Update settings"
end

def edit_site_plan(options = {})
  visit_settings(options[:id] || @current_user.sites.last.id)
  choose "plan_id_enterprise"
  click_button "Update plan"
end

def edit_site_addons(options = {})
  visit_settings(options[:id] || @current_user.sites.last.id)
  check "SSL serving"

  click_button "Update addons"
end

def visit_settings(id)
  within(:css, "tr#site_#{id}") do
    click_link "Settings"
  end
end