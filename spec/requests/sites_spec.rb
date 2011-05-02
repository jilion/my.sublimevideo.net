require 'spec_helper'

feature "Sites" do
  before(:all) do
    plans_attributes = [
      { name: "dev",        cycle: "none",  player_hits: 0,          price: 0 },
      { name: "sponsored",  cycle: "none",  player_hits: 0,          price: 0 },
      { name: "beta",       cycle: "none",  player_hits: 0,          price: 0 },
      { name: "comet",      cycle: "month", player_hits: 3_000,      price: 990 },
      { name: "planet",     cycle: "month", player_hits: 50_000,     price: 1990 },
      { name: "star",       cycle: "month", player_hits: 200_000,    price: 4990 },
      { name: "galaxy",     cycle: "month", player_hits: 1_000_000,  price: 9990 },
      { name: "comet",      cycle: "year",  player_hits: 3_000,      price: 9900 },
      { name: "planet",     cycle: "year",  player_hits: 50_000,     price: 19900 },
      { name: "star",       cycle: "year",  player_hits: 200_000,    price: 49900 },
      { name: "galaxy",     cycle: "year",  player_hits: 1_000_000,  price: 99900 },
      { name: "custom1",    cycle: "year",  player_hits: 10_000_000, price: 999900 }
    ]
    plans_attributes.each { |attributes| Plan.create(attributes) }
  end

  context "with a user with no credit card registered" do
    background do
      sign_in_as :user, :without_cc => true
      visit "/sites/new"
    end

    describe "new" do
      describe "dev plan" do
        scenario "with no hostname" do
          choose "plan_dev"
          has_checked_field?("plan_dev").should be_true

          fill_in "Domain", :with => ""
          click_button "Create site"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == ""
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('add a hostname')
          page.should_not have_content('Choose a plan')
          page.should have_content('LaunchPad')
        end

        scenario "with a hostname" do
          choose "plan_dev"
          has_checked_field?("plan_dev").should be_true
          fill_in "Domain", :with => "rymai.com"
          click_button "Create site"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('rymai.com')
          page.should have_content('Choose a plan')
          page.should have_content('LaunchPad')
        end
      end

      describe "paid plan" do
        context "entering no credit card" do
          scenario "with no hostname" do
            choose "plan_comet_month"
            has_checked_field?("plan_comet_month").should be_true
            fill_in "Domain", :with => ""
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Domain can't be blank")
            page.should have_content("Card type is invalid")
            page.should have_content("Name on card can't be blank")
            page.should have_content("Card number is invalid")
            page.should have_content("CSC is required")
          end

          scenario "with a hostname" do
            choose "plan_comet_month"
            has_checked_field?("plan_comet_month").should be_true
            fill_in "Domain", :with => "rymai.com"
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Card type is invalid")
            page.should have_content("Name on card can't be blank")
            page.should have_content("Card number is invalid")
            page.should have_content("Expiration date expired")
            page.should have_content("CSC is required")
          end
        end

        context "entering a credit card" do
          scenario "with no hostname" do
            choose "plan_comet_year"
            has_checked_field?("plan_comet_year").should be_true
            fill_in "Domain", :with => ""
            set_credit_card
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Domain can't be blank")
          end # entering a credit card with no hostname

          scenario "with a hostname (visa)" do
            choose "plan_comet_year"
            has_checked_field?("plan_comet_year").should be_true
            fill_in "Domain", :with => "rymai.com"
            set_credit_card
            VCR.use_cassette('ogone/visa_payment_acceptance') { click_button "Create" }

            @worker.work_off
            site = @current_user.sites.last
            site.last_invoice.reload.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_js_hash)
            site.plan_id.should == Plan.find_by_name_and_cycle("comet", "year").id
            site.pending_plan_id.should be_nil
            site.first_paid_plan_started_at.should be_present
            site.plan_started_at.should be_present
            site.plan_cycle_started_at.should be_present
            site.plan_cycle_ended_at.should be_present
            site.pending_plan_started_at.should be_nil
            site.pending_plan_cycle_started_at.should be_nil
            site.pending_plan_cycle_ended_at.should be_nil

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Site was successfully created.")
            page.should have_content('rymai.com')
            page.should have_content('Comet (yearly)')
          end # entering a credit card with a hostname

          scenario "with a hostname (mastercard)" do
            choose "plan_comet_year"
            has_checked_field?("plan_comet_year").should be_true
            fill_in "Domain", :with => "rymai.com"
            set_credit_card(type: 'master')
            VCR.use_cassette('ogone/master_payment_acceptance') { click_button "Create" }

            @worker.work_off
            site = @current_user.sites.last
            site.last_invoice.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_js_hash)
            site.plan_id.should == Plan.find_by_name_and_cycle("comet", "year").id
            site.pending_plan_id.should be_nil
            site.first_paid_plan_started_at.should be_present
            site.plan_started_at.should be_present
            site.plan_cycle_started_at.should be_present
            site.plan_cycle_ended_at.should be_present
            site.pending_plan_started_at.should be_nil
            site.pending_plan_cycle_started_at.should be_nil
            site.pending_plan_cycle_ended_at.should be_nil

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Site was successfully created.")
            page.should have_content('rymai.com')
            page.should have_content('Comet (yearly)')
          end # entering a credit card with a hostname

          scenario "entering a 3-D Secure credit card with a failing identification" do
            choose "plan_comet_year"
            has_checked_field?("plan_comet_year").should be_true
            fill_in "Domain", :with => "rymai.com"
            set_credit_card(d3d: true)
            VCR.use_cassette('ogone/visa_payment_acceptance_3ds') { click_button "Create" }
            @worker.work_off
            site = @current_user.sites.last
            transaction = site.last_invoice.last_transaction
            transaction.should be_waiting_d3d
            site.last_invoice.should be_open

            # fake payment succeeded callback (and thus skip the d3d redirection)
            transaction.process_payment_response("PAYID" => "1234", "NCSTATUS" => "3", "STATUS" => "2", "orderID" => transaction.id.to_s)
            transaction.reload.should be_failed
            site.reload.last_invoice.should be_failed
            site.invoices_failed?.should be_true
            site.plan_id.should be_nil
            site.pending_plan_id.should == Plan.find_by_name_and_cycle("comet", "year").id
            site.first_paid_plan_started_at.should be_nil
            site.plan_started_at.should be_nil
            site.plan_cycle_started_at.should be_nil
            site.plan_cycle_ended_at.should be_nil
            site.pending_plan_started_at.should be_present
            site.pending_plan_cycle_started_at.should be_present
            site.pending_plan_cycle_ended_at.should be_present

            site.cdn_up_to_date.should be_false
            site.license.should be_blank
            site.loader.should be_blank

            visit "/sites"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_no_content("Site was successfully created.")
            page.should have_content('rymai.com')
            page.should have_no_content('Comet (yearly)')
            page.should have_no_selector('.usage_bar')
            page.should have_no_selector('.embed_code')
            page.should have_no_content(I18n.t('site.status.ok'))
            page.should have_content(I18n.t('site.status.payment_issue'))
          end

          scenario "entering a 3-D Secure credit card with a succeeding identification" do
            choose "plan_comet_year"
            has_checked_field?("plan_comet_year").should be_true
            fill_in "Domain", :with => "rymai.com"
            set_credit_card(d3d: true)
            VCR.use_cassette('ogone/visa_payment_acceptance_3ds') { click_button "Create site" }
            @worker.work_off
            site = @current_user.sites.last
            transaction = site.last_invoice.last_transaction
            transaction.should be_waiting_d3d
            site.last_invoice.should be_open

            # fake payment succeeded callback (and thus skip the d3d redirection)
            transaction.process_payment_response("PAYID" => "1234", "NCSTATUS" => "0", "STATUS" => "9", "orderID" => transaction.id.to_s)
            transaction.reload.should be_paid

            @worker.work_off
            site = @current_user.sites.last

            site.last_invoice.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_js_hash)
            site.plan_id.should == Plan.find_by_name_and_cycle("comet", "year").id
            site.pending_plan_id.should be_nil
            site.first_paid_plan_started_at.should be_present
            site.plan_started_at.should be_present
            site.plan_cycle_started_at.should be_present
            site.plan_cycle_ended_at.should be_present
            site.pending_plan_started_at.should be_nil
            site.pending_plan_cycle_started_at.should be_nil
            site.pending_plan_cycle_ended_at.should be_nil

            visit "/sites"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content('rymai.com')
            page.should have_content('Comet (yearly)')
            page.should have_selector('.usage_bar')
            page.should have_content(I18n.t('site.status.ok'))
          end
        end # paid plan entering a credit card
      end

      describe "custom plan" do
        background do
          visit "/sites/new?custom_plan=#{Plan.find_by_name_and_cycle("custom1", "year").token}"
        end

        context "entering no credit card" do
          scenario "with no hostname" do
            choose "plan_custom"
            has_checked_field?("plan_custom").should be_true
            fill_in "Domain", :with => ""
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Domain can't be blank")
            page.should have_content("Card type is invalid")
            page.should have_content("Name on card can't be blank")
            page.should have_content("Card number is invalid")
            page.should have_content("CSC is required")
          end

          scenario "with a hostname" do
            choose "plan_custom"
            has_checked_field?("plan_custom").should be_true
            fill_in "Domain", :with => "rymai.com"
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Card type is invalid")
            page.should have_content("Name on card can't be blank")
            page.should have_content("Card number is invalid")
            page.should have_content("CSC is required")
          end
        end # custom plan entering no credit card

        context "entering a credit card" do
          scenario "with no hostname" do
            choose "plan_custom"
            has_checked_field?("plan_custom").should be_true
            fill_in "Domain", :with => ""
            set_credit_card
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Domain can't be blank")
          end

          scenario "with a hostname" do
            choose "plan_custom"
            has_checked_field?("plan_custom").should be_true
            fill_in "Domain", :with => "rymai.com"
            set_credit_card
            VCR.use_cassette('ogone/visa_payment_acceptance') { click_button "Create" }

            @worker.work_off
            site = @current_user.sites.last
            site.last_invoice.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_js_hash)
            site.plan_id.should == Plan.find_by_name_and_cycle("custom1", "year").id
            site.pending_plan_id.should be_nil
            site.first_paid_plan_started_at.should be_present
            site.plan_started_at.should be_present
            site.plan_cycle_started_at.should be_present
            site.plan_cycle_ended_at.should be_present
            site.pending_plan_started_at.should be_nil
            site.pending_plan_cycle_started_at.should be_nil
            site.pending_plan_cycle_ended_at.should be_nil

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Site was successfully created.")
            page.should have_content('rymai.com')
            page.should have_content('Custom')
            page.should have_content(I18n.l(site.plan_cycle_started_at, :format => :d_b_Y) + ' - ' + I18n.l(site.plan_cycle_ended_at, :format => :d_b_Y))
          end
        end # custom plan entering a credit card
      end # custom plan
    end
  end

  context "with a user with a credit card registered" do
    background do
      sign_in_as :user, :without_cc => false
      visit "/sites/new"
    end

    describe "new" do
      describe "in dev plan" do
        scenario "with no hostname" do
          page.should have_no_selector("#credit_card")
          page.should have_selector("#credit_card_summary")

          choose "plan_dev"
          has_checked_field?("plan_dev").should be_true

          fill_in "Domain", :with => ""
          click_button "Create site"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == ""
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('add a hostname')
          page.should_not have_content('Choose a plan')
          page.should have_content('LaunchPad')
        end

        scenario "with a hostname" do
          choose "plan_dev"
          has_checked_field?("plan_dev").should be_true
          fill_in "Domain", :with => "rymai.com"
          click_button "Create site"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('rymai.com')
          page.should have_content('Choose a plan')
          page.should have_content('LaunchPad')
        end
      end

      describe "paid plan" do
        scenario "with no hostname" do
          page.should have_no_selector("#credit_card")
          page.should have_selector("#credit_card_summary")

          choose "plan_comet_month"
          has_checked_field?("plan_comet_month").should be_true
          fill_in "Domain", :with => ""

          click_button "Create"

          current_url.should =~ %r(http://[^/]+/sites)

          page.should have_content("Domain can't be blank")
          page.should have_no_selector("#credit_card")
          page.should have_no_content("Card type is invalid")
          page.should have_no_content("Name on card can't be blank")
          page.should have_no_content("Card number is invalid")
          page.should have_no_content("CSC is required")
        end

        scenario "with a hostname (visa)" do
          page.should have_no_selector("#credit_card")
          choose "plan_comet_year"
          has_checked_field?("plan_comet_year").should be_true
          fill_in "Domain", :with => "rymai.com"
          page.should have_no_selector("#credit_card")
          VCR.use_cassette('ogone/visa_payment_acceptance') { click_button "Create" }

          @worker.work_off
          site = @current_user.sites.last
          site.last_invoice.reload.should be_paid
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should == Plan.find_by_name_and_cycle("comet", "year").id
          site.pending_plan_id.should be_nil
          site.first_paid_plan_started_at.should be_present
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_present
          site.plan_cycle_ended_at.should be_present
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content("Site was successfully created.")
          page.should have_content('rymai.com')
          page.should have_content('Comet (yearly)')
        end

        scenario "with a hostname (mastercard)" do
          choose "plan_comet_year"
          has_checked_field?("plan_comet_year").should be_true
          fill_in "Domain", :with => "rymai.com"
          page.should have_no_selector("#credit_card")
          page.should have_selector("#credit_card_summary")
          VCR.use_cassette('ogone/master_payment_acceptance') { click_button "Create" }

          @worker.work_off
          site = @current_user.sites.last
          site.last_invoice.should be_paid
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should == Plan.find_by_name_and_cycle("comet", "year").id
          site.pending_plan_id.should be_nil
          site.first_paid_plan_started_at.should be_present
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_present
          site.plan_cycle_ended_at.should be_present
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content("Site was successfully created.")
          page.should have_content('rymai.com')
          page.should have_content('Comet (yearly)')
        end
      end

      describe "custom plan" do
        background do
          visit "/sites/new?custom_plan=#{Plan.find_by_name_and_cycle("custom1", "year").token}"
        end

        scenario "with no hostname" do
          page.should have_no_selector("#credit_card")
          page.should have_selector("#credit_card_summary")
          choose "plan_custom"
          has_checked_field?("plan_custom").should be_true
          fill_in "Domain", :with => ""
          click_button "Create"

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_no_selector("#credit_card")
          page.should have_content("Domain can't be blank")
          page.should have_no_content("Card type is invalid")
          page.should have_no_content("Name on card can't be blank")
          page.should have_no_content("Card number is invalid")
          page.should have_no_content("CSC is required")
        end

        scenario "with a hostname" do
          page.should have_no_selector("#credit_card")
          choose "plan_custom"
          has_checked_field?("plan_custom").should be_true
          fill_in "Domain", :with => "rymai.com"
          VCR.use_cassette('ogone/visa_payment_acceptance') { click_button "Create" }

          @worker.work_off
          site = @current_user.sites.last
          site.last_invoice.should be_paid
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_js_hash)
          site.plan_id.should == Plan.find_by_name_and_cycle("custom1", "year").id
          site.pending_plan_id.should be_nil
          site.first_paid_plan_started_at.should be_present
          site.plan_started_at.should be_present
          site.plan_cycle_started_at.should be_present
          site.plan_cycle_ended_at.should be_present
          site.pending_plan_started_at.should be_nil
          site.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content("Site was successfully created.")
          page.should have_content('rymai.com')
          page.should have_content('Custom')
          page.should have_content(I18n.l(site.plan_cycle_started_at, :format => :d_b_Y) + ' - ' + I18n.l(site.plan_cycle_ended_at, :format => :d_b_Y))
        end
      end # custom plan
    end

    describe "edit" do
      scenario "edit a site" do
        site = Factory(:site, user: @current_user, plan_id: @dev_plan.id, hostname: 'rymai.com')

        visit "/sites"
        page.should have_content('rymai.com')
        click_link "Edit rymai.com"
        fill_in "Development domains", :with => "rymai.local"
        click_button "Update settings"

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('rymai.com')

        @current_user.sites.last.dev_hostnames.should == "rymai.local"
      end
    end

  end

  context "no matter if the user has a credit card or not" do
    background do
      sign_in_as :user
    end

    scenario "user suspended" do
      @current_user.suspend
      visit "/sites"

      current_url.should =~ %r(http://[^/]+/suspended)
    end

    describe "navigation" do
      context "when the user has no sites" do
        scenario "should redirect to /sites/new" do
          visit "/sites"
          page.should have_content('Choose a plan for your site')
        end
      end

      context "when user has already some sites" do
        background do
          @site = Factory(:site_with_invoice, :user => @current_user, :hostname => 'rymai.com')
        end

        scenario "when user has already some sites" do
          visit "/sites"
          click_link "Add a site"
          page.should have_content('Choose a plan for your site')
        end

        scenario "edit a site" do
          visit "/sites"
          page.should have_content('rymai.com')

          click_link "Edit rymai.com"
          current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/edit)
          page.should have_content('rymai.com')

          page.should have_content I18n.t('site.edit.delete_site_info1', domain: "rymai.com")
          page.should have_content I18n.t('site.edit.delete_site_info2')

          click_link "Change plan"
          current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/plan/edit)
          page.should have_selector('#change_plan_box.section_box')

          click_link "Invoices"
          current_url.should =~ %r(http://[^/]+/sites/#{@site.token}/invoices)
          page.should have_content('Next invoice')
          page.should have_content('Past invoices')
        end
      end
    end

    describe "archive" do
      scenario "a paid site with no not paid invoices" do
        site = Factory(:site, :user => @current_user, :hostname => 'google.com')

        visit "/sites"
        page.should have_content('google.com')
        @current_user.sites.last.hostname.should == "google.com"
        VoxcastCDN.stub_chain(:delay, :purge).twice

        click_link "Edit google.com"
        click_button "Delete site"

        fill_in "Password", :with => "123456"
        click_button "Done"

        page.should_not have_content('google.com')
        @current_user.sites.not_archived.should be_empty
      end

      scenario "a paid site with an open invoices" do
        site = Factory(:site, :user => @current_user, :hostname => 'google.com')
        Factory(:invoice, site: site, state: 'open')

        visit "/sites"
        page.should have_content('google.com')
        @current_user.sites.last.hostname.should == "google.com"

        page.should have_no_content('Delete site')
      end

      scenario "a paid site with an failed invoices" do
        site = Factory(:site, :user => @current_user, :hostname => 'google.com')
        Factory(:invoice, site: site, state: 'failed')

        visit "/sites"
        page.should have_content('google.com')
        @current_user.sites.last.hostname.should == "google.com"

        page.should have_no_content('Delete site')
      end

      scenario "a paid site with an waiting invoices" do
        site = Factory(:site, :user => @current_user, :hostname => 'google.com')
        Factory(:invoice, site: site, state: 'waiting')

        visit "/sites"
        page.should have_content('google.com')
        @current_user.sites.last.hostname.should == "google.com"

        page.should have_no_content('Delete site')
      end

      scenario "a pending paid site with an open invoice" do
        site = Factory(:new_site, :user => @current_user, :hostname => 'google.com', first_paid_plan_started_at: nil)
        site.first_paid_plan_started_at.should be_nil
        Factory(:invoice, site: site, state: 'open')

        visit "/sites"
        page.should have_content('google.com')
        @current_user.sites.last.hostname.should == "google.com"
        VoxcastCDN.stub_chain(:delay, :purge).twice

        click_link "Edit google.com"
        click_button "Delete site"

        page.should_not have_content('google.com')
        @current_user.sites.not_archived.should be_empty
      end

      scenario "a pending paid site with a failed invoice" do
        site = Factory(:new_site, :user => @current_user, :hostname => 'google.com', first_paid_plan_started_at: nil)
        site.first_paid_plan_started_at.should be_nil
        Factory(:invoice, site: site, state: 'failed')

        visit "/sites"
        page.should have_content('google.com')
        @current_user.sites.last.hostname.should == "google.com"
        VoxcastCDN.stub_chain(:delay, :purge).twice

        click_link "Edit google.com"
        click_button "Delete site"

        page.should_not have_content('google.com')
        @current_user.sites.not_archived.should be_empty
      end

      scenario "a pending paid site with a waiting invoice" do
        site = Factory(:new_site, :user => @current_user, :hostname => 'google.com', first_paid_plan_started_at: nil)
        site.first_paid_plan_started_at.should be_nil
        Factory(:invoice, site: site, state: 'open')

        visit "/sites"
        page.should have_content('google.com')
        @current_user.sites.last.hostname.should == "google.com"

        page.should have_no_content('Delete site')
      end
    end

    describe "index" do
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
    end
  end

end
