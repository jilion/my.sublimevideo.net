require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'New site' do
  let(:hostname) { 'rymai.com' }

  context 'with a user with no credit card registered' do
    background do
      sign_in_as :user, without_cc: true
      go 'my', '/sites/new'
    end

    describe 'trial plan' do
      scenario 'with no hostname' do
        fill_in 'Domain', with: ''
        click_button 'Add site'

        last_site_should_be_created_with_no_invoice('', @trial_plan)
      end

      scenario 'with a hostname' do
        fill_in 'Domain', with: hostname
        click_button 'Add site'

        last_site_should_be_created_with_no_invoice(hostname, @trial_plan)
      end
    end # trial plan

    describe 'free plan' do
      scenario 'with no hostname' do
        check 'site_skip_trial'
        choose 'plan_free'

        fill_in 'Domain', with: ''
        click_button 'Add site'

        last_site_should_be_created_with_no_invoice('', @free_plan)
      end

      scenario 'with a hostname' do
        check 'site_skip_trial'
        choose 'plan_free'
        fill_in 'Domain', with: hostname
        click_button 'Add site'

        last_site_should_be_created_with_no_invoice(hostname, @free_plan)
      end
    end # free plan

    describe 'paid plan' do
      context 'with no hostname' do
        scenario 'shows an error' do
          check 'site_skip_trial'
          has_checked_field?('site_skip_trial').should be_true
          choose 'plan_plus_month'
          has_checked_field?('plan_plus_month').should be_true
          fill_in 'Domain', with: ''
          expect { click_button 'Add site' }.to_not change(@current_user.invoices, :count).by(1)

          current_url.should eq 'http://my.sublimevideo.dev/sites'
          page.should have_content 'Domain can\'t be blank'
        end
      end

      context 'with a hostname' do
        scenario 'creation is successful and site is in trial' do
          check 'site_skip_trial'
          has_checked_field?('site_skip_trial').should be_true
          choose 'plan_plus_month'
          has_checked_field?('plan_plus_month').should be_true
          fill_in 'Domain', with: hostname
          expect { click_button 'Add site' }.to change(@current_user.invoices, :count).by(1)

          last_site_should_be_created_and_invoice_failed(hostname, Plan.find_by_name_and_cycle('plus', 'month'))
        end
      end
    end # paid plan

    describe 'custom plan' do
      background do
        go 'my', "/sites/new?custom_plan=#{@custom_plan.token}"
      end

      context 'with no hostname' do
        scenario 'shows an error' do
          has_checked_field?('plan_custom').should be_true
          fill_in 'Domain', with: ''
          expect { click_button 'Create' }.to_not change(@current_user.invoices, :count)

          current_url.should eq 'http://my.sublimevideo.dev/sites'
          page.should have_content 'Domain can\'t be blank'
        end
      end

      context 'with a hostname' do
        scenario 'creation is succesful' do
          has_checked_field?('plan_custom').should be_true
          fill_in 'Domain', with: hostname
          expect { click_button 'Create' }.to change(@current_user.invoices, :count)

          last_site_should_be_created_and_invoice_failed(hostname, @custom_plan)
        end
      end
    end # custom plan
  end

  context 'with a user with a credit card registered' do
    background do
      sign_in_as :user
      go 'my', '/sites/new'
    end

    describe 'trial plan' do
      scenario 'with no hostname' do
        fill_in 'Domain', with: ''
        click_button 'Add site'

        last_site_should_be_created_with_no_invoice('', @trial_plan)
      end

      scenario 'with a hostname' do
        fill_in 'Domain', with: hostname
        click_button 'Add site'

        last_site_should_be_created_with_no_invoice(hostname, @trial_plan)
      end
    end # trial plan

    describe 'paid plan' do
      scenario 'creation is successful' do
        check 'site_skip_trial'
        has_checked_field?('site_skip_trial').should be_true
        choose 'plan_plus_month'
        has_checked_field?('plan_plus_month').should be_true
        fill_in 'Domain', with: hostname
        check 'site_skip_trial'
        VCR.use_cassette('ogone/visa_payment_generic') do
          expect { click_button 'Add site' }.to change(@current_user.invoices, :count)
        end

        last_site_should_be_created_and_invoice_paid(hostname, Plan.find_by_name_and_cycle('plus', 'month'))
      end
    end # paid plan

    describe 'custom plan' do
      let(:plan) { @custom_plan }
      background do
        go 'my', "/sites/new?custom_plan=#{plan.token}"
      end

      scenario 'creation is succesful' do
        has_checked_field?('plan_custom').should be_true
        fill_in 'Domain', with: hostname
        VCR.use_cassette('ogone/visa_payment_generic') do
          expect { click_button 'Add site' }.to change(@current_user.invoices, :count)
        end

        last_site_should_be_created_and_invoice_paid(hostname, plan)
      end
    end # custom plan

  end

end

feature 'Edit site' do
  let(:hostname1)    { 'rymai.com' }
  let(:hostname2)    { 'rymai.eu' }
  let(:hostname3)    { 'rymai.ch' }
  let(:dev_hostname) { 'rymai.local' }

  background do
    sign_in_as :user
    @free_site     = create(:site, user: @current_user, plan_id: @free_plan.id, hostname: hostname1)
    @site_in_trial = create(:site, user: @current_user, plan_id: @trial_plan.id, hostname: hostname2)
    @paid_site     = create(:site, user: @current_user, hostname: hostname3)

    @free_site.should be_badged
    @site_in_trial.should_not be_badged
    @paid_site.should_not be_badged
    go 'my', '/sites'
  end

  scenario 'edit a free site' do
    click_link "Edit #{hostname1}"

    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'
    page.should have_no_selector 'input#site_badged'

    fill_in 'site_extra_hostnames', with: hostname2
    fill_in 'site_dev_hostnames', with: dev_hostname
    click_button 'Save settings'

    current_url.should eq 'http://my.sublimevideo.dev/sites'

    @free_site.reload.hostname.should eq hostname1
    @free_site.extra_hostnames.should eq hostname2
    @free_site.dev_hostnames.should eq dev_hostname
    @free_site.should be_badged
  end

  scenario 'edit a site in trial' do
    click_link "Edit #{hostname2}"

    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'
    page.should have_selector 'input#site_badged'
    has_checked_field?('site_badged').should be_false

    fill_in 'site_extra_hostnames', with: hostname1
    fill_in 'site_dev_hostnames', with: dev_hostname
    check 'site_badged'
    click_button 'Save settings'

    current_url.should eq 'http://my.sublimevideo.dev/sites'

    @site_in_trial.reload.hostname.should eq hostname2
    @site_in_trial.extra_hostnames.should eq hostname1
    @site_in_trial.dev_hostnames.should eq dev_hostname
    @site_in_trial.should be_badged
  end

  scenario 'edit a paying site' do
    click_link "Edit #{hostname3}"

    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'
    page.should have_selector 'input#site_badged'
    has_checked_field?('site_badged').should be_false

    fill_in 'site_extra_hostnames', with: hostname2
    fill_in 'site_dev_hostnames', with: dev_hostname
    check 'site_badged'
    click_button 'Save settings'

    fill_in 'Password', with: '123456'
    click_button 'Done'

    current_url.should eq 'http://my.sublimevideo.dev/sites'

    @paid_site.reload.hostname.should eq hostname3
    @paid_site.extra_hostnames.should eq hostname2
    @paid_site.dev_hostnames.should eq dev_hostname
    @paid_site.should be_badged
  end

end

feature 'Site archive' do
  let(:hostname1) { 'rymai.com' }
  let(:hostname2) { 'rymai.eu' }
  let(:hostname3) { 'rymai.ch' }

  background do
    sign_in_as :user
    @site_in_trial = create(:site, user: @current_user, plan_id: @trial_plan.id, hostname: hostname1)

    @paid_site_with_paid_invoices = create(:site_not_in_trial, user: @current_user, hostname: hostname2)
    create(:invoice, site: @paid_site_with_paid_invoices, state: 'paid')

    @paid_site_with_open_invoices = create(:site_not_in_trial, user: @current_user, hostname: hostname3)
    create(:invoice, site: @paid_site_with_open_invoices, state: 'open')

    go 'my', '/sites'
  end

  scenario 'a paid site in trial' do
    click_link "Edit #{hostname1}"
    click_button 'Delete site'

    page.should have_no_content hostname1
    @site_in_trial.reload.should be_archived
  end

  scenario 'a paid site with only paid invoices' do
    click_link "Edit #{hostname2}"
    click_button 'Delete site'
    fill_in 'Password', with: '123456'
    click_button 'Done'

    page.should have_no_content hostname2
    @paid_site_with_paid_invoices.reload.should be_archived
  end

  scenario 'a paid site with an open invoice' do
    click_link "Edit #{hostname3}"
    click_button 'Delete site'
    fill_in 'Password', with: '123456'
    click_button 'Done'

    page.should have_no_content hostname3
    @paid_site_with_open_invoices.reload.should be_archived
  end

  scenario 'a paid site with a failed invoice' do
    site = create(:site, user: @current_user, hostname: 'test.com')
    create(:invoice, site: site, state: 'failed')

    go 'my', '/sites'
    click_link 'Edit test.com'
    click_button 'Delete site'
    fill_in 'Password', with: '123456'
    click_button 'Done'

    page.should have_no_content 'test.com'
    site.reload.should be_archived
  end

  scenario 'a paid site with a waiting invoice' do
    site = create(:site, user: @current_user, hostname: 'example.org')
    create(:invoice, site: site, state: 'waiting')

    go 'my', '/sites'
    click_link 'Edit example.org'
    click_button 'Delete site'
    fill_in 'Password', with: '123456'
    click_button 'Done'

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

def last_site_should_be_created_with_no_invoice(hostname, plan)
  site = @current_user.sites.last
  $worker.work_off
  site.reload
  site.hostname.should eq hostname
  site.loader.read.should include(site.token)
  site.license.read.should include(site.license_js_hash)

  current_url.should eq 'http://my.sublimevideo.dev/sites'
  page.should have_content (hostname.present? ? hostname : 'add a hostname')
  page.should have_content 'Site was successfully created.'
  page.should have_content (site.in_trial_plan? ? 'Trial' : "#{plan.title} plan")
end

def last_site_should_be_created_and_invoice_paid(hostname, plan)
  site = @current_user.sites.last
  $worker.work_off
  site.reload
  site.invoices.last.should be_paid
  site.hostname.should eq hostname
  site.loader.read.should include(site.token)
  site.license.read.should include(site.license_js_hash)
  site.plan_id.should eq plan.id
  site.pending_plan_id.should be_nil
  site.first_paid_plan_started_at.should be_present
  site.plan_started_at.should be_present
  site.plan_cycle_started_at.should be_present
  site.plan_cycle_ended_at.should be_present
  site.pending_plan_started_at.should be_nil
  site.pending_plan_cycle_started_at.should be_nil
  site.pending_plan_cycle_ended_at.should be_nil

  current_url.should eq 'http://my.sublimevideo.dev/sites'
  page.should have_content hostname
  page.should have_content 'Site was successfully created.'
  page.should have_content (site.in_trial_plan? ? 'Trial' : "#{plan.title} plan")
end

def last_site_should_be_created_and_invoice_failed(hostname, plan)
  site = @current_user.sites.last
  $worker.work_off
  site.reload
  site.invoices.last.should be_failed
  site.hostname.should eq hostname
  site.loader.read.should be_nil
  site.license.read.should be_nil
  site.plan_id.should be_nil
  site.pending_plan_id.should eq plan.id
  site.first_paid_plan_started_at.should be_present
  site.plan_started_at.should be_nil
  site.plan_cycle_started_at.should be_nil
  site.plan_cycle_ended_at.should be_nil
  site.pending_plan_started_at.should be_present
  site.pending_plan_cycle_started_at.should be_present
  site.pending_plan_cycle_ended_at.should be_present

  current_url.should eq 'http://my.sublimevideo.dev/sites'
  page.should have_content hostname
  page.should have_content (site.in_trial_plan? ? 'Trial' : "#{plan.title} plan")
end
