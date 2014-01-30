require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'New site' do
  background do
    sign_in_as :user
    go 'my', '/sites/new'
  end

  scenario 'with no hostname' do
    fill_in 'Main domain', with: ''
    click_button 'Next'

    last_site_should_be_created('please-edit.me')
  end

  scenario 'with a hostname' do
    fill_in 'Main domain', with: hostname1
    click_button 'Next'

    last_site_should_be_created(hostname1)
  end
end

feature 'Edit site' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user, hostname: hostname1)
    SiteManager.new(@site).create

    go 'my', '/sites'
  end

  scenario 'edit a site' do
    within "#site_actions_#{@site.id}" do
      click_link 'Settings'
    end

    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'

    fill_in 'site_extra_hostnames', with: hostname2
    fill_in 'site_dev_hostnames', with: dev_hostname
    click_button 'Save settings'

    current_url.should =~ %r(^http://[^/]+/sites/#{@site.token}/edit$)

    @site.reload.hostname.should eq hostname1
    @site.extra_hostnames.should eq hostname2
    @site.dev_hostnames.should eq dev_hostname
  end
end

feature 'Archive site' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user, hostname: hostname1)
    SiteManager.new(@site).create

    @paid_site_with_paid_invoices = build(:site, user: @current_user, hostname: hostname2)
    SiteManager.new(@paid_site_with_paid_invoices).create
    create(:paid_invoice, site: @paid_site_with_paid_invoices)

    @paid_site_with_open_invoices = build(:site, user: @current_user, hostname: hostname3)
    SiteManager.new(@paid_site_with_open_invoices).create
    create(:invoice, site: @paid_site_with_open_invoices)

    go 'my', '/sites'
  end

  scenario 'a paid site with no invoices' do
    within "#site_actions_#{@site.id}" do
      click_link 'Settings'
    end
    click_button 'Cancel site'

    page.should have_no_content hostname1
    @site.reload.should be_archived
  end

  scenario 'a paid site with only paid invoices' do
    within "#site_actions_#{@paid_site_with_paid_invoices.id}" do
      click_link 'Settings'
    end
    click_button 'Cancel site'

    page.should have_no_content hostname2
    @paid_site_with_paid_invoices.reload.should be_archived
  end

  scenario 'a paid site with an open invoice' do
    within "#site_actions_#{@paid_site_with_open_invoices.id}" do
      click_link 'Settings'
    end
    page.should have_no_content 'Cancel site'
  end

  scenario 'a paid site with a failed invoice' do
    site = build(:site, user: @current_user, hostname: 'test.com')
    SiteManager.new(site).create
    create(:failed_invoice, site: site)

    go 'my', '/sites'
    within "#site_actions_#{site.id}" do
      click_link 'Settings'
    end
    page.should have_no_content 'Cancel site'
  end

  scenario 'a paid site with a waiting invoice' do
    site = build(:site, user: @current_user, hostname: 'example.org')
    SiteManager.new(site).create
    create(:waiting_invoice, site: site)

    go 'my', '/sites'
    within "#site_actions_#{site.id}" do
      click_link 'Settings'
    end
    page.should have_no_content 'Cancel site'
  end
end

feature 'Sites index' do
  background do
    sign_in_as :user
  end

  context 'suspended user' do
    background do
      @current_user.suspend
    end

    scenario 'is redirected to the /suspended page' do
      go 'my', '/sites'
      current_url.should eq 'http://my.sublimevideo.dev/suspended'
    end
  end

  context 'active user' do
    context 'with no sites' do
      scenario 'should redirect to /assistant/new-site' do
        go 'my', '/sites'
        current_url.should eq 'http://my.sublimevideo.dev/assistant/new-site'
      end
    end

    context 'with sites' do
      background do
        @site = build(:site, user: @current_user, hostname: hostname1)
        SiteManager.new(@site).create
      end

      scenario 'sort buttons displayed only if count of sites > 1' do
        go 'my', '/sites'
        page.should have_content hostname1
        page.should have_no_css 'div.sorting'
        page.should have_no_css 'a.sort'

        SiteManager.new(build(:site, user: @current_user, hostname: hostname2)).create
        go 'my', '/sites'

        page.should have_content hostname1
        page.should have_content hostname2
        page.should have_css 'div.sorting'
        page.should have_css 'a.sort.date'
        page.should have_css 'a.sort.hostname'
      end

      scenario 'pagination links displayed only if count of sites > Site.per_page' do
        PaginatedResponder.stub(:per_page).and_return(1)
        go 'my', '/sites'

        page.should have_no_css 'nav.pagination'
        page.should have_no_selector 'a[rel=\'next\']'

        SiteManager.new(build(:site, user: @current_user, hostname: hostname3)).create
        go 'my', '/sites'

        page.should have_css 'nav.pagination'
        page.should have_selector 'a[rel=\'next\']'
      end
    end
  end
end

def last_site_should_be_created(hostname)
  site = @current_user.sites.last
  Sidekiq::Worker.clear_all
  site.reload
  site.hostname.should eq hostname
  site.kits.should have(1).item
  site.default_kit.should eq site.kits.first
  site.designs.should have(3).items
  site.addon_plans.should have(13).items

  current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/player"
  page.should have_content hostname
  page.should have_content 'Site has been successfully registered.'
end

def hostname1;    'rymai.com'; end
def hostname2;    'rymai.eu'; end
def hostname3;    'rymai.ch'; end
def dev_hostname; 'rymai.local'; end
