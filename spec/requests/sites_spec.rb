require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'New site' do
  background do
    sign_in_as :user
    go 'my', '/sites/new'
  end

  scenario 'with no hostname' do
    fill_in 'Domain', with: ''
    click_button 'Add site'

    last_site_should_be_created('please-edit.me')
  end

  scenario 'with a hostname' do
    fill_in 'Domain', with: hostname1
    click_button 'Add site'

    last_site_should_be_created(hostname1)
  end
end

feature 'Edit site' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user, hostname: hostname1)
    Service::Site.new(@site).initial_save

    go 'my', '/sites'
  end

  scenario 'edit a site', :js do
    select 'Settings', from: "site_actions_#{@site.id}"

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

feature 'Archive site', :js do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user, hostname: hostname1)
    Service::Site.new(@site).initial_save

    @paid_site_with_paid_invoices = build(:site, user: @current_user, hostname: hostname2)
    Service::Site.new(@paid_site_with_paid_invoices).initial_save
    create(:paid_invoice, site: @paid_site_with_paid_invoices)

    @paid_site_with_open_invoices = build(:site, user: @current_user, hostname: hostname3)
    Service::Site.new(@paid_site_with_open_invoices).initial_save
    create(:invoice, site: @paid_site_with_open_invoices)

    go 'my', '/sites'
  end

  scenario 'a paid site with no invoices' do
    select 'Settings', from: "site_actions_#{@site.id}"
    click_button 'Cancel site'

    page.should have_no_content hostname1
    @site.reload.should be_archived
  end

  scenario 'a paid site with only paid invoices' do
    select 'Settings', from: "site_actions_#{@paid_site_with_paid_invoices.id}"
    click_button 'Cancel site'

    page.should have_no_content hostname2
    @paid_site_with_paid_invoices.reload.should be_archived
  end

  scenario 'a paid site with an open invoice' do
    select 'Settings', from: "site_actions_#{@paid_site_with_open_invoices.id}"
    page.should have_no_content 'Cancel site'
  end

  scenario 'a paid site with a failed invoice' do
    site = build(:site, user: @current_user, hostname: 'test.com')
    Service::Site.new(site).initial_save
    create(:failed_invoice, site: site)

    go 'my', '/sites'
    select 'Settings', from: "site_actions_#{site.id}"
    page.should have_no_content 'Cancel site'
  end

  scenario 'a paid site with a waiting invoice' do
    site = build(:site, user: @current_user, hostname: 'example.org')
    Service::Site.new(site).initial_save
    create(:waiting_invoice, site: site)

    go 'my', '/sites'
    select 'Settings', from: "site_actions_#{site.id}"
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
      scenario 'should redirect to /sites/new' do
        go 'my', '/sites'
        current_url.should eq 'http://my.sublimevideo.dev/sites/new'
      end
    end

    context 'with sites' do
      background do
        @site = build(:site, user: @current_user, hostname: hostname1)
        Service::Site.new(@site).initial_save
      end

      scenario 'sort buttons displayed only if count of sites > 1' do
        go 'my', '/sites'
        page.should have_content hostname1
        page.should have_no_css 'div.sorting'
        page.should have_no_css 'a.sort'

        Service::Site.new(build(:site, user: @current_user, hostname: hostname2)).initial_save
        go 'my', '/sites'

        page.should have_content hostname1
        page.should have_content hostname2
        page.should have_css 'div.sorting'
        page.should have_css 'a.sort.date'
        page.should have_css 'a.sort.hostname'
      end

      scenario 'pagination links displayed only if count of sites > Site.per_page' do
        Responders::PaginatedResponder.stub(:per_page).and_return(1)
        go 'my', '/sites'

        page.should have_no_css 'nav.pagination'
        page.should have_no_selector 'a[rel=\'next\']'

        Service::Site.new(build(:site, user: @current_user, hostname: hostname3)).initial_save
        go 'my', '/sites'

        page.should have_css 'nav.pagination'
        page.should have_selector 'a[rel=\'next\']'
      end

      context 'user has billable views' do
        background do
          create(:site_day_stat, t: @site.token, d: 30.days.ago.midnight, pv: { e: 1 }, vv: { m: 2 })
        end

        scenario 'views notice 1' do
          go 'my', '/sites'
          page.should have_selector '.hidable_notice[data-notice-id=\'1\']'
        end
      end
    end
  end
end

def last_site_should_be_created(hostname)
  site = @current_user.sites.last
  $worker.work_off
  site.reload
  site.hostname.should eq hostname
  site.app_designs.should have(3).items
  site.addon_plans.should have(9).items

  current_url.should eq 'http://my.sublimevideo.dev/sites'
  page.should have_content (hostname.present? ? hostname : 'add a hostname')
  page.should have_content 'Site has been successfully created.'
end

def hostname1;    'rymai.com'; end
def hostname2;    'rymai.eu'; end
def hostname3;    'rymai.ch'; end
def dev_hostname; 'rymai.local'; end
