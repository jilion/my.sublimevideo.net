require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature "Sites" do
  before(:all) { create_plans }

  context "with a user with no credit card registered" do
    background do
      sign_in_as :user, without_cc: true
    end

    describe "new" do
      background do
        visit "/sites/new"
      end

      describe "free plan" do
        scenario "with no hostname" do
          choose "plan_free"
          has_checked_field?("plan_free").should be_true

          fill_in "Domain", with: ""
          click_button "Create site"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == ""
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('add a hostname')
          page.should have_content('Free')
        end

        scenario "with a hostname" do
          choose "plan_free"
          has_checked_field?("plan_free").should be_true
          fill_in "Domain", with: "rymai.com"
          click_button "Create site"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('rymai.com')
          page.should have_content('Free')
        end
      end

      describe "paid plan" do
        scenario "with no hostname" do
          choose "plan_silver_month"
          has_checked_field?("plan_silver_month").should be_true
          fill_in "Domain", with: ""
          expect { click_button "Create" }.to_not change(@current_user.invoices, :count)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content("Domain can't be blank")
        end

        scenario "with a hostname" do
          choose "plan_silver_month"
          has_checked_field?("plan_silver_month").should be_true
          fill_in "Domain", with: "rymai.com"
          expect { click_button "Create" }.to_not change(@current_user.invoices, :count)

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should == Plan.find_by_name_and_cycle("silver", "month").id
          site.pending_plan_id.should be_nil
          site.trial_started_at.should be_present
          site.first_paid_plan_started_at.should be_nil
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_nil
          site.plan_cycle_ended_at.should be_nil
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content("Site was successfully created.")
          page.should have_content('rymai.com')
          page.should have_content('Silver')
        end

        # pending "entering a 3-D Secure credit card with a failing identification" do
        #   choose "plan_silver_year"
        #   has_checked_field?("plan_silver_year").should be_true
        #   fill_in "Domain", with: "rymai.com"
        #   set_credit_card(d3d: true)
        #   VCR.use_cassette('ogone/visa_payment_acceptance_3ds') { click_button "Create" }
        #   @worker.work_off
        #   site = @current_user.sites.last
        #   transaction = site.last_invoice.last_transaction
        #   transaction.should be_waiting_d3d
        #   site.last_invoice.should be_open
        #
        #   # fake payment succeeded callback (and thus skip the d3d redirection)
        #   transaction.process_payment_response("PAYID" => "1234", "NCSTATUS" => "3", "STATUS" => "2", "orderID" => transaction.id.to_s)
        #   transaction.reload.should be_failed
        #   site.reload.last_invoice.should be_failed
        #   site.invoices_failed?.should be_true
        #   site.plan_id.should be_nil
        #   site.pending_plan_id.should == Plan.find_by_name_and_cycle("silver", "year").id
        #   site.first_paid_plan_started_at.should be_nil
        #   site.plan_started_at.should be_nil
        #   site.plan_cycle_started_at.should be_nil
        #   site.plan_cycle_ended_at.should be_nil
        #   site.pending_plan_started_at.should be_present
        #   site.pending_plan_cycle_started_at.should be_present
        #   site.pending_plan_cycle_ended_at.should be_present
        #
        #   @worker.work_off
        #   site.reload.cdn_up_to_date.should be_true
        #   site.loader.read.should include(site.token)
        #   site.license.read.should include(site.license_js_hash)
        #
        #   visit "/sites"
        #
        #   current_url.should =~ %r(http://[^/]+/sites)
        #   page.should have_no_content("Site was successfully created.")
        #   page.should have_content('rymai.com')
        #   page.should have_no_content('Comet (yearly)')
        #   page.should have_no_selector('.usage_bar')
        #   page.should have_no_selector('.embed_code')
        #   page.should have_no_content(I18n.t('site.status.ok'))
        #   page.should have_content(I18n.t('site.status.payment_issue'))
        # end

        # pending "entering a 3-D Secure credit card with a succeeding identification" do
        #   choose "plan_silver_year"
        #   has_checked_field?("plan_silver_year").should be_true
        #   fill_in "Domain", with: "rymai.com"
        #   set_credit_card(d3d: true)
        #   VCR.use_cassette('ogone/visa_payment_acceptance_3ds') { click_button "Create site" }
        #   @worker.work_off
        #   site = @current_user.sites.last
        #   transaction = site.last_invoice.last_transaction
        #   transaction.should be_waiting_d3d
        #   site.last_invoice.should be_open
        #
        #   # fake payment succeeded callback (and thus skip the d3d redirection)
        #   transaction.process_payment_response("PAYID" => "1234", "NCSTATUS" => "0", "STATUS" => "9", "orderID" => transaction.id.to_s)
        #   transaction.reload.should be_paid
        #
        #   @worker.work_off
        #   site = @current_user.sites.last.reload
        #
        #   site.last_invoice.should be_paid
        #   site.hostname.should == "rymai.com"
        #   site.loader.read.should include(site.token)
        #   site.license.read.should include(site.license_js_hash)
        #   site.plan_id.should == Plan.find_by_name_and_cycle("silver", "year").id
        #   site.pending_plan_id.should be_nil
        #   site.first_paid_plan_started_at.should be_present
        #   site.plan_started_at.should be_present
        #   site.plan_cycle_started_at.should be_present
        #   site.plan_cycle_ended_at.should be_present
        #   site.pending_plan_started_at.should be_nil
        #   site.pending_plan_cycle_started_at.should be_nil
        #   site.pending_plan_cycle_ended_at.should be_nil
        #
        #   visit "/sites"
        #
        #   current_url.should =~ %r(http://[^/]+/sites)
        #   page.should have_content('rymai.com')
        #   page.should have_content('Comet (yearly)')
        #   page.should have_selector('.usage_bar')
        #   page.should have_content(I18n.t('site.status.ok'))
        # end
      end

      describe "custom plan" do
        background do
          visit "/sites/new?custom_plan=#{Plan.find_by_name_and_cycle("custom1", "year").token}"
        end

        scenario "with no hostname" do
          choose "plan_custom"
          has_checked_field?("plan_custom").should be_true
          fill_in "Domain", with: ""
          expect { click_button "Create" }.to_not change(@current_user.invoices, :count)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content("Domain can't be blank")
        end

        scenario "with a hostname" do
          choose "plan_custom"
          has_checked_field?("plan_custom").should be_true
          fill_in "Domain", with: "rymai.com"
          expect { click_button "Create" }.to_not change(@current_user.invoices, :count)

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should == Plan.find_by_name_and_cycle("custom1", "year").id
          site.pending_plan_id.should be_nil
          site.trial_started_at.should be_present
          site.first_paid_plan_started_at.should be_nil
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_nil
          site.plan_cycle_ended_at.should be_nil
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content("Site was successfully created.")
          page.should have_content('rymai.com')
          page.should have_content('Custom')
          page.should have_content(I18n.l(site.trial_started_at + BusinessModel.days_for_trial.days, format: :d_b_Y))
        end
      end # custom plan
    end

  end

  context "with a user with a credit card registered" do
    background do
      sign_in_as :user, without_cc: false
      visit "/sites/new"
    end

  end

  context "no matter if the user has a credit card or not" do
    background do
      sign_in_as :user
    end

    context "suspended user" do
      background do
        @current_user.suspend
      end

      scenario "is redirected to the /suspended page" do
        visit "/sites"
        current_url.should =~ %r(http://[^/]+/suspended)
      end
    end

    context "active user" do
      background do
        visit "/sites"
      end

      context "with no sites" do

        describe "navigation" do
          scenario "should redirect to /sites/new" do
            page.should have_selector("#signup_steps")
            find('#signup_steps').find('li.active').should have_content('2')
            page.should have_no_selector("h2")
          end
        end

      end

      context "with a free site" do
        background do
          @site = Factory.create(:site, user: @current_user, hostname: 'rymai.com', plan_id: @free_plan.id)
          visit "/sites"
        end

        scenario "the Invoices tab is not visible" do
          page.should have_content('rymai.com')

          click_link "Edit rymai.com"

          page.should have_no_content('Invoices')
          page.should have_no_selector("a[href='/sites/#{@site.token}/invoices']")

          visit "/sites/#{@site.token}/invoices"

          current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/invoices)
          page.should have_content('No invoices')
        end

        context "with an invoice" do
          background do
            Factory.create(:invoice, site: @site, state: 'paid', paid_at: Time.now.utc)
          end

          scenario "all tabs are visible and accessible" do
            page.should have_content('rymai.com')

            click_link "Edit rymai.com"
            current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/edit)
            page.should have_content('rymai.com')

            page.should have_content strip_tags(I18n.t('site.edit.delete_site_info1', domain: "rymai.com"))
            page.should have_content I18n.t('site.edit.delete_site_info2')

            click_link "Plan"
            current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/plan/edit)
            page.should have_selector('#change_plan_box.section_box')

            page.should have_content('Invoices')
            page.should have_selector("a[href='/sites/#{@site.token}/invoices']")

            click_link "Invoices"

            current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/invoices)
            page.should have_no_content('No invoices')
            page.should have_no_content('Next invoice')
            page.should have_content('Past invoices')
          end
        end

      end

      context "with a site without invoice" do
        background do
          @site = Factory.create(:site, user: @current_user, hostname: 'rymai.com')
          visit "/sites"
        end

        describe "new" do
          scenario "don't display signup steps" do
            click_link "Add a site"
            page.should have_no_selector("#signup_steps")
            find('h2').should have_content('Choose a plan for your site')
          end
        end

        describe "site's tabs" do
          scenario "all tabs are visible and accessible" do
            page.should have_content('rymai.com')

            click_link "Edit rymai.com"
            current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/edit)
            page.should have_content('rymai.com')

            page.should have_content strip_tags(I18n.t('site.edit.delete_site_info1', domain: "rymai.com"))
            page.should have_content I18n.t('site.edit.delete_site_info2')

            click_link "Plan"
            current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/plan/edit)
            page.should have_selector('#change_plan_box.section_box')

            page.should have_content('Invoices')
            page.should have_selector("a[href='/sites/#{@site.token}/invoices']")

            click_link "Invoices"

            current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/invoices)
            page.should have_content('No invoices')
          end
        end

      end

      context "with at least a site with an invoice" do
        background do
          @site = Factory.create(:site_with_invoice, user: @current_user, hostname: 'rymai.com')
          visit "/sites"
        end

        describe "site's tabs" do
          scenario "the Invoice tab is accessible" do
            page.should have_content('rymai.com')

            click_link "Edit rymai.com"
            page.should have_no_content('No invoices')
            page.should have_content('Invoices')
            page.should have_selector("a[href='/sites/#{@site.token}/invoices']")
            click_link "Invoices"

            current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/invoices)
            page.should have_no_content('No invoices')
            page.should have_content('Next invoice')
            page.should have_content('Past invoices')
          end
        end
      end

      describe "edit" do
        background do
          @free_site = Factory.create(:site, user: @current_user, plan_id: @free_plan.id, hostname: 'rymai.com')

          @paid_site_in_trial = Factory.create(:site, user: @current_user, hostname: 'rymai.eu')

          @paid_site_not_in_trial = Factory.create(:site_not_in_trial, user: @current_user, hostname: 'rymai.ch')

          @free_site.should be_badged
          @paid_site_in_trial.should_not be_badged
          @paid_site_not_in_trial.should_not be_badged
          visit "/sites"
        end

        scenario "edit a free site" do
          page.should have_content('rymai.com')
          click_link "Edit rymai.com"

          page.should have_selector("input#site_dev_hostnames")
          page.should have_selector("input#site_extra_hostnames")
          page.should have_selector("input#site_path")
          page.should have_selector("input#site_wildcard")
          page.should have_no_selector("input#site_badged")

          fill_in "site_extra_hostnames", with: "rymai.me"
          fill_in "site_dev_hostnames", with: "rymai.local"
          click_button "Save settings"

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('rymai.com')

          @free_site.reload.extra_hostnames.should == "rymai.me"
          @free_site.dev_hostnames.should == "rymai.local"
          @free_site.should be_badged
        end

        scenario "edit a paying site in trial" do
          page.should have_content('rymai.eu')
          click_link "Edit rymai.eu"

          page.should have_selector("input#site_extra_hostnames")
          page.should have_selector("input#site_dev_hostnames")
          page.should have_selector("input#site_path")
          page.should have_selector("input#site_wildcard")
          page.should have_selector("input#site_badged")
          has_checked_field?("site_badged").should be_false

          fill_in "site_extra_hostnames", with: "rymai.fr"
          fill_in "site_dev_hostnames", with: "rymai.dev"
          check "site_badged"
          click_button "Save settings"

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('rymai.eu')

          @paid_site_in_trial.reload.extra_hostnames.should == "rymai.fr"
          @paid_site_in_trial.dev_hostnames.should == "rymai.dev"
          @paid_site_in_trial.should be_badged
        end

        scenario "edit a paying site not in trial" do
          visit "/sites"
          page.should have_content('rymai.ch')
          click_link "Edit rymai.ch"

          page.should have_selector("input#site_extra_hostnames")
          page.should have_selector("input#site_dev_hostnames")
          page.should have_selector("input#site_path")
          page.should have_selector("input#site_wildcard")
          page.should have_selector("input#site_badged")
          has_checked_field?("site_badged").should be_false

          fill_in "site_extra_hostnames", with: "rymai.es"
          fill_in "site_dev_hostnames", with: "rymai.dev"
          check "site_badged"
          click_button "Save settings"

          fill_in "Password", with: "123456"
          click_button "Done"

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('rymai.ch')

          @paid_site_not_in_trial.reload.extra_hostnames.should eq "rymai.es"
          @paid_site_not_in_trial.dev_hostnames.should eq "rymai.dev"
          @paid_site_not_in_trial.should be_badged
        end
      end

      describe "archive" do
        background do
          @paid_site_in_trial = Factory.create(:site, user: @current_user, hostname: 'rymai.me')

          @paid_site_with_paid_invoices = Factory.create(:site_not_in_trial, user: @current_user, hostname: 'rymai.fr')
          Factory.create(:invoice, site: @paid_site_with_paid_invoices, state: 'paid')

          @paid_site_with_open_invoices = Factory.create(:site_not_in_trial, user: @current_user, hostname: 'rymai.ch')
          Factory.create(:invoice, site: @paid_site_with_open_invoices, state: 'open')

          visit "/sites"
        end

        scenario "a paid site in trial" do
          page.should have_content('rymai.me')

          click_link "Edit rymai.me"
          click_button "Delete site"

          page.should have_no_content('rymai.me')
          @paid_site_in_trial.reload.should be_archived
        end

        scenario "a paid site with only paid invoices" do
          page.should have_content('rymai.fr')

          click_link "Edit rymai.fr"
          click_button "Delete site"

          fill_in "Password", with: "123456"
          click_button "Done"

          page.should have_no_content('rymai.fr')
          @paid_site_with_paid_invoices.reload.should be_archived
        end

        scenario "a paid site with an open invoices" do
          page.should have_content('rymai.ch')

          page.should have_no_content('Delete site')
          @paid_site_with_open_invoices.should_not be_archived
        end

        scenario "a paid site with a failed invoice" do
          site = Factory.create(:site_not_in_trial, user: @current_user, hostname: 'google.com')
          Factory.create(:invoice, site: site, state: 'failed')

          visit "/sites"
          page.should have_content('google.com')
          @current_user.sites.last.hostname.should == "google.com"

          page.should have_no_content('Delete site')
        end

        scenario "a paid site with a waiting invoice" do
          site = Factory.create(:site_not_in_trial, user: @current_user, hostname: 'google.com')
          Factory.create(:invoice, site: site, state: 'waiting')

          visit "/sites"
          page.should have_content('google.com')
          @current_user.sites.last.hostname.should == "google.com"

          page.should have_no_content('Delete site')
        end
      end

      describe "index" do
        background do
          @site = Factory.create(:site, user: @current_user, hostname: 'google.com')
          visit "/sites"
        end

        scenario "sort buttons displayed only if count of sites > 1" do
          page.should have_content('google.com')
          page.should have_no_css('div.sorting')
          page.should have_no_css('a.sort')

          Factory.create(:site, user: @current_user, hostname: 'google2.com')
          visit "/sites"

          page.should have_content('google.com')
          page.should have_content('google2.com')
          page.should have_css('div.sorting')
          page.should have_css('a.sort.date')
          page.should have_css('a.sort.hostname')
        end

        scenario "pagination links displayed only if count of sites > Site.per_page" do
          Responders::PaginatedResponder.stub(:per_page).and_return(1)
          visit "/sites"

          page.should have_no_content('Next')
          page.should have_no_css('nav.pagination')
          page.should have_no_css('span.next')

          Factory.create(:site, user: @current_user, hostname: 'google2.com')
          visit "/sites"

          page.should have_css('nav.pagination')
          page.should have_css('span.prev')
          page.should have_css('em.current')
          page.should have_css('a.next')
        end

        context "user has billable views" do
          background do
            Factory.create(:site_stat, t: @site.token, d: 30.days.ago.midnight, pv: { e: 1 }, vv: { m: 2 })
          end

          scenario "views notice 1" do
            visit "/sites"
            page.should have_selector(".hidable_notice[data-notice-id='1']")
          end

        end
      end

    end

  end

end
