require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'New site' do
  let(:hostname) { 'rymai.com' }

  background do
    sign_in_as :user
    go 'my', '/sites/new'
  end

  scenario 'with no hostname' do
    fill_in 'Domain', with: ''
    click_button 'Add site'

    last_site_should_be_created('')
  end

  scenario 'with a hostname' do
    fill_in 'Domain', with: hostname
    click_button 'Add site'

    last_site_should_be_created(hostname)
  end
end

feature 'Edit site' do
  let(:hostname1)    { 'rymai.com' }
  let(:hostname2)    { 'rymai.eu' }
  let(:hostname3)    { 'rymai.ch' }
  let(:dev_hostname) { 'rymai.local' }

  background do
    sign_in_as :user
    @site = create(:site, user: @current_user, hostname: hostname1)

    go 'my', '/sites'
  end

  scenario 'edit a site' do
    click_link "Edit #{hostname1}"

    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'

    fill_in 'site_extra_hostnames', with: hostname2
    fill_in 'site_dev_hostnames', with: dev_hostname
    click_button 'Save settings'

    current_url.should eq 'http://my.sublimevideo.dev/sites'

    @site.reload.hostname.should eq hostname1
    @site.extra_hostnames.should eq hostname2
    @site.dev_hostnames.should eq dev_hostname
  end

end

feature 'Site archive' do
  let(:hostname1) { 'rymai.com' }
  let(:hostname2) { 'rymai.eu' }
  let(:hostname3) { 'rymai.ch' }

  background do
    sign_in_as :user
    @site = create(:site, user: @current_user, hostname: hostname1)

    @paid_site_with_paid_invoices = create(:site, user: @current_user, hostname: hostname2)
    create(:invoice, site: @paid_site_with_paid_invoices, state: 'paid')

    @paid_site_with_open_invoices = create(:site, user: @current_user, hostname: hostname3)
    create(:invoice, site: @paid_site_with_open_invoices, state: 'open')

    go 'my', '/sites'
  end

  scenario 'a paid site in trial' do
    click_link "Edit #{hostname1}"
    click_button 'Delete site'

    page.should have_no_content hostname1
    @site.reload.should be_archived
  end

  scenario 'a paid site with only paid invoices' do
    click_link "Edit #{hostname2}"
    click_button 'Delete site'
    # fill_in 'Password', with: '123456'
    # click_button 'Done'

    page.should have_no_content hostname2
    @paid_site_with_paid_invoices.reload.should be_archived
  end

  scenario 'a paid site with an open invoice' do
    click_link "Edit #{hostname3}"
    click_button 'Delete site'
    # fill_in 'Password', with: '123456'
    # click_button 'Done'

    page.should have_no_content hostname3
    @paid_site_with_open_invoices.reload.should be_archived
  end

  scenario 'a paid site with a failed invoice' do
    site = create(:site, user: @current_user, hostname: 'test.com')
    create(:invoice, site: site, state: 'failed')

    go 'my', '/sites'
    click_link 'Edit test.com'
    click_button 'Delete site'
    # fill_in 'Password', with: '123456'
    # click_button 'Done'

    page.should have_no_content 'test.com'
    site.reload.should be_archived
  end

  scenario 'a paid site with a waiting invoice' do
    site = create(:site, user: @current_user, hostname: 'example.org')
    create(:invoice, site: site, state: 'waiting')

    go 'my', '/sites'
    click_link 'Edit example.org'
    click_button 'Delete site'
    # fill_in 'Password', with: '123456'
    # click_button 'Done'

    page.should have_no_content 'example.org'
    site.reload.should be_archived
  end
end

feature 'Sites index' do
  let(:hostname1) { 'rymai.com' }
  let(:hostname2) { 'rymai.eu' }

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
        @site = create(:site, user: @current_user, hostname: hostname1)
      end

      scenario 'sort buttons displayed only if count of sites > 1' do
        go 'my', '/sites'
        page.should have_content hostname1
        page.should have_no_css 'div.sorting'
        page.should have_no_css 'a.sort'

        create(:site, user: @current_user, hostname: hostname2)
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

        create(:site, user: @current_user, hostname: 'google2.com')
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
  site.addons.active.should =~ [@logo_sublime_addon, @support_standard_addon]

  # FIXME
  # site.loader.read.should include(site.token)
  # site.license.read.should include(site.license_js_hash)

  current_url.should eq 'http://my.sublimevideo.dev/sites'
  page.should have_content (hostname.present? ? hostname : 'add a hostname')
  page.should have_content 'Site was successfully created.'
end
