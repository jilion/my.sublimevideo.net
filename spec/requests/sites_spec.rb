require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'New site' do

  context 'with a user with no credit card registered' do
    background do
      sign_in_as :user, without_cc: true
      go 'my', '/sites/new'
    end

    describe 'trial plan' do
      scenario 'with no hostname' do
        fill_in 'Domain', with: ''
        click_button 'Create site'

        $worker.work_off
        site = @current_user.sites.last
        site.hostname.should eq ''
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_js_hash)

        current_url.should eq 'http://my.sublimevideo.dev/sites'
        page.should have_content 'add a hostname'
        page.should have_content 'Trial'
      end

      scenario 'with a hostname' do
        fill_in 'Domain', with: 'rymai.com'
        click_button 'Create site'

        $worker.work_off
        site = @current_user.sites.last
        site.hostname.should eq 'rymai.com'
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_js_hash)

        current_url.should eq 'http://my.sublimevideo.dev/sites'
        page.should have_content 'rymai.com'
        page.should have_content 'Trial'
      end
    end

    describe 'free plan' do
      scenario 'with no hostname' do
        choose 'plan_free'
        has_checked_field?('plan_free').should be_true

        fill_in 'Domain', with: ''
        click_button 'Create site'

        $worker.work_off
        site = @current_user.sites.last
        site.hostname.should eq ''
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_js_hash)

        current_url.should eq 'http://my.sublimevideo.dev/sites'
        page.should have_content 'add a hostname'
        page.should have_content 'Free'
      end

      scenario 'with a hostname' do
        choose 'plan_free'
        has_checked_field?('plan_free').should be_true
        fill_in 'Domain', with: 'rymai.com'
        click_button 'Create site'

        $worker.work_off
        site = @current_user.sites.last
        site.hostname.should eq 'rymai.com'
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_js_hash)

        current_url.should eq 'http://my.sublimevideo.dev/sites'
        page.should have_content 'rymai.com'
        page.should have_content 'Free'
      end
    end

    describe 'paid plan' do
      context 'with no hostname' do
        scenario 'shows an error' do
          choose 'plan_plus_month'
          has_checked_field?('plan_plus_month').should be_true
          fill_in 'Domain', with: ''
          expect { click_button 'Create' }.to_not change(@current_user.invoices, :count)

          current_url.should eq 'http://my.sublimevideo.dev/sites'
          page.should have_content 'Domain can\'t be blank'
        end
      end

      context 'with a hostname' do
        scenario 'creation is successful and site is in trial' do
          choose 'plan_plus_month'
          has_checked_field?('plan_plus_month').should be_true
          fill_in 'Domain', with: 'rymai.com'
          expect { click_button 'Create' }.to_not change(@current_user.invoices, :count)

          $worker.work_off
          site = @current_user.sites.last
          site.hostname.should eq 'rymai.com'
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should eq Plan.find_by_name_and_cycle('plus', 'month').id
          site.pending_plan_id.should be_nil
          site.trial_started_at.should be_present
          site.first_paid_plan_started_at.should be_nil
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_nil
          site.plan_cycle_ended_at.should be_nil
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should eq 'http://my.sublimevideo.dev/sites'

          # page.should have_content 'Site was successfully created.'
          page.should have_content 'rymai.com'
          page.should have_content 'Plus'
        end

        describe 'user wants to skip trial' do
          scenario 'creation is successful and site is not in trial but with a transaction error' do
            choose 'plan_plus_month'
            has_checked_field?('plan_plus_month').should be_true
            fill_in 'Domain', with: 'rymai.com'
            check 'site_skip_trial'
            expect { click_button 'Create' }.to change(@current_user.invoices, :count).by(1)

            $worker.work_off
            site = @current_user.sites.last
            site.invoices.last.should be_failed
            site.hostname.should eq 'rymai.com'
            site.loader.read.should be_nil
            site.license.read.should be_nil
            site.plan_id.should be_nil
            site.pending_plan_id.should eq Plan.find_by_name_and_cycle('plus', 'month').id
            site.trial_started_at.should be_present
            site.first_paid_plan_started_at.should be_present
            site.plan_started_at.should be_nil
            site.plan_cycle_started_at.should be_nil
            site.plan_cycle_ended_at.should be_nil
            site.pending_plan_started_at.should be_present
            site.pending_plan_cycle_started_at.should be_present
            site.pending_plan_cycle_ended_at.should be_present

            current_url.should eq 'http://my.sublimevideo.dev/sites'
            # page.should have_content 'Site was successfully created.'
            page.should have_content 'rymai.com'
            page.should have_no_content 'Plus'
          end
        end
      end
    end

    describe 'custom plan' do
      background do
        go 'my', '/sites/new?custom_plan=#{@custom_plan.token}'
      end

      context 'with no hostname' do
        scenario 'shows an error' do
          choose 'plan_custom'
          has_checked_field?('plan_custom').should be_true
          fill_in 'Domain', with: ''
          expect { click_button 'Create' }.to_not change(@current_user.invoices, :count)

          current_url.should eq 'http://my.sublimevideo.dev/sites'
          page.should have_content 'Domain can\'t be blank'
        end
      end

      context 'with a hostname' do
        scenario 'creation is succesful and site is in trial' do
          choose 'plan_custom'
          has_checked_field?('plan_custom').should be_true
          fill_in 'Domain', with: 'rymai.com'
          expect { click_button 'Create' }.to_not change(@current_user.invoices, :count)

          $worker.work_off
          site = @current_user.sites.last
          site.hostname.should eq 'rymai.com'
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should eq @custom_plan.id
          site.pending_plan_id.should be_nil
          site.trial_started_at.should be_present
          site.first_paid_plan_started_at.should be_nil
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_nil
          site.plan_cycle_ended_at.should be_nil
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should eq 'http://my.sublimevideo.dev/sites'
          # page.should have_content 'Site was successfully created.'
          page.should have_content 'rymai.com'
          page.should have_content 'Custom'
          page.should have_content I18n.l(site.trial_end, format: :d_b_Y)
        end
      end
    end # custom plan
  end

  context 'with a user with a credit card registered' do
    background do
      sign_in_as :user, without_cc: false
      go 'my', '/sites/new'
    end

    describe 'paid plan' do
      context 'with a hostname' do
        scenario 'creation is successful and site is in trial' do
          choose 'plan_plus_month'
          has_checked_field?('plan_plus_month').should be_true
          fill_in 'Domain', with: 'rymai.com'
          expect { click_button 'Create' }.to_not change(@current_user.invoices, :count)

          $worker.work_off
          site = @current_user.sites.last
          site.hostname.should eq 'rymai.com'
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should eq Plan.find_by_name_and_cycle('plus', 'month').id
          site.pending_plan_id.should be_nil
          site.trial_started_at.should be_present
          site.first_paid_plan_started_at.should be_nil
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_nil
          site.plan_cycle_ended_at.should be_nil
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should eq 'http://my.sublimevideo.dev/sites'
          # page.should have_content 'Site was successfully created.'
          page.should have_content 'rymai.com'
          page.should have_content 'Plus'
        end

        describe 'user wants to skip trial' do
          scenario 'creation is successful and site is not in trial and with no transaction error' do
            choose 'plan_plus_month'
            has_checked_field?('plan_plus_month').should be_true
            fill_in 'Domain', with: 'rymai.com'
            check 'site_skip_trial'
            VCR.use_cassette('ogone/visa_payment_generic') do
              expect { click_button 'Create' }.to change(@current_user.invoices, :count)
            end

            $worker.work_off
            site = @current_user.sites.last
            site.invoices.last.should be_paid
            site.hostname.should eq 'rymai.com'
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_js_hash)
            site.plan_id.should eq Plan.find_by_name_and_cycle('plus', 'month').id
            site.pending_plan_id.should be_nil
            site.trial_started_at.should be_present
            site.first_paid_plan_started_at.should be_present
            site.plan_started_at.should be_present
            site.plan_cycle_started_at.should be_present
            site.plan_cycle_ended_at.should be_present
            site.pending_plan_started_at.should be_nil
            site.pending_plan_cycle_started_at.should be_nil
            site.pending_plan_cycle_ended_at.should be_nil

            current_url.should eq 'http://my.sublimevideo.dev/sites'
            # page.should have_content 'Site was successfully created.'
            page.should have_content 'rymai.com'
            page.should have_content 'Plus'
          end
        end
      end
    end
  end

end

feature 'Edit site' do
  background do
    sign_in_as :user
    @free_site = create(:site, user: @current_user, plan_id: @free_plan.id, hostname: 'rymai.com')

    @paid_site_in_trial = create(:site, user: @current_user, hostname: 'rymai.eu')

    @paid_site_not_in_trial = create(:site_not_in_trial, user: @current_user, hostname: 'rymai.ch')

    @free_site.should be_badged
    @paid_site_in_trial.should_not be_badged
    @paid_site_not_in_trial.should_not be_badged
    go 'my', '/sites'
  end

  scenario 'edit a free site' do
    click_link 'Edit rymai.com'

    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'
    page.should have_no_selector 'input#site_badged'

    fill_in 'site_extra_hostnames', with: 'rymai.me'
    fill_in 'site_dev_hostnames', with: 'rymai.local'
    click_button 'Save settings'

    current_url.should eq 'http://my.sublimevideo.dev/sites'
    page.should have_content 'rymai.com'

    @free_site.reload.extra_hostnames.should eq 'rymai.me'
    @free_site.dev_hostnames.should eq 'rymai.local'
    @free_site.should be_badged
  end

  scenario 'edit a paying site in trial' do
    click_link 'Edit rymai.eu'

    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'
    page.should have_selector 'input#site_badged'
    has_checked_field?('site_badged').should be_false

    fill_in 'site_extra_hostnames', with: 'rymai.fr'
    fill_in 'site_dev_hostnames', with: 'rymai.dev'
    check 'site_badged'
    click_button 'Save settings'

    current_url.should eq 'http://my.sublimevideo.dev/sites'
    page.should have_content 'rymai.eu'

    @paid_site_in_trial.reload.extra_hostnames.should eq 'rymai.fr'
    @paid_site_in_trial.dev_hostnames.should eq 'rymai.dev'
    @paid_site_in_trial.should be_badged
  end

  scenario 'edit a paying site not in trial' do
    click_link 'Edit rymai.ch'

    page.should have_selector 'input#site_extra_hostnames'
    page.should have_selector 'input#site_dev_hostnames'
    page.should have_selector 'input#site_path'
    page.should have_selector 'input#site_wildcard'
    page.should have_selector 'input#site_badged'
    has_checked_field?('site_badged').should be_false

    fill_in 'site_extra_hostnames', with: 'rymai.es'
    fill_in 'site_dev_hostnames', with: 'rymai.dev'
    check 'site_badged'
    click_button 'Save settings'

    fill_in 'Password', with: '123456'
    click_button 'Done'

    current_url.should eq 'http://my.sublimevideo.dev/sites'
    page.should have_content 'rymai.ch'

    @paid_site_not_in_trial.reload.extra_hostnames.should eq 'rymai.es'
    @paid_site_not_in_trial.dev_hostnames.should eq 'rymai.dev'
    @paid_site_not_in_trial.should be_badged
  end

end

feature 'Site archive' do
  background do
    sign_in_as :user
  end

  describe 'archive' do
    background do
      @paid_site_in_trial = create(:site, user: @current_user, hostname: 'rymai.me')

      @paid_site_with_paid_invoices = create(:site_not_in_trial, user: @current_user, hostname: 'rymai.fr')
      create(:invoice, site: @paid_site_with_paid_invoices, state: 'paid')

      @paid_site_with_open_invoices = create(:site_not_in_trial, user: @current_user, hostname: 'rymai.ch')
      create(:invoice, site: @paid_site_with_open_invoices, state: 'open')

      go 'my', '/sites'
    end

    scenario 'a paid site in trial' do
      click_link 'Edit rymai.me'
      click_button 'Delete site'

      page.should have_no_content 'rymai.me'
      @paid_site_in_trial.reload.should be_archived
    end

    scenario 'a paid site with only paid invoices' do
      click_link 'Edit rymai.fr'
      click_button 'Delete site'

      fill_in 'Password', with: '123456'
      click_button 'Done'

      page.should have_no_content 'rymai.fr'
      @paid_site_with_paid_invoices.reload.should be_archived
    end

    scenario 'a paid site with an open invoices' do
      page.should have_content 'rymai.ch'

      page.should have_no_content 'Delete site'
      @paid_site_with_open_invoices.should_not be_archived
    end

    scenario 'a paid site with a failed invoice' do
      site = create(:site_not_in_trial, user: @current_user, hostname: 'google.com')
      create(:invoice, site: site, state: 'failed')

      go 'my', '/sites'
      page.should have_content 'google.com'
      @current_user.sites.last.hostname.should eq 'google.com'

      page.should have_no_content 'Delete site'
    end

    scenario 'a paid site with a waiting invoice' do
      site = create(:site_not_in_trial, user: @current_user, hostname: 'google.com')
      create(:invoice, site: site, state: 'waiting')

      go 'my', '/sites'
      page.should have_content('google.com')
      @current_user.sites.last.hostname.should eq 'google.com'

      page.should have_no_content('Delete site')
    end
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
        @site = create(:site, user: @current_user, hostname: 'google.com')
      end

      scenario 'sort buttons displayed only if count of sites > 1' do
        go 'my', '/sites'
        page.should have_content 'google.com'
        page.should have_no_css 'div.sorting'
        page.should have_no_css 'a.sort'

        create(:site, user: @current_user, hostname: 'google2.com')
        go 'my', '/sites'

        page.should have_content 'google.com'
        page.should have_content 'google2.com'
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
