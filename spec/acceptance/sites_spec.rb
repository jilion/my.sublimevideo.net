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

    feature "new" do
      describe "dev plan" do
        background do
          choose "plan_dev"
        end

        scenario "with no hostname" do
          fill_in "Domain", :with => ""
          click_button "Create"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == ""
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('add a hostname')
          page.should have_content('Sandbox')
        end

        scenario "with a hostname" do
          fill_in "Domain", :with => "rymai.com"
          click_button "Create"

          @worker.work_off
          site = @current_user.sites.last
          site.hostname.should == "rymai.com"
          site.loader.read.should include(site.token)
          site.license.read.should include(site.license_hash)

          current_url.should =~ %r(http://[^/]+/sites)
          page.should have_content('rymai.com')
          page.should have_content('Sandbox')
        end
      end

      describe "paid plan" do
        background do
          choose "plan_comet_month"
        end

        context "entering no credit card" do
          scenario "with no hostname" do
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
            fill_in "Domain", :with => "rymai.com"
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Card type is invalid")
            page.should have_content("Name on card can't be blank")
            page.should have_content("Card number is invalid")
            page.should have_content("CSC is required")
          end
        end

        context "entering a credit card" do
          background do
            choose "plan_comet_year"
          end

          scenario "with no hostname" do
            fill_in "Domain", :with => ""
            set_credit_card_in_site_form
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Domain can't be blank")
          end # entering a credit card with no hostname

          scenario "with a hostname (visa)" do
            fill_in "Domain", :with => "rymai.com"
            set_credit_card_in_site_form
            VCR.use_cassette('ogone/visa_payment_acceptance') { click_button "Create" }

            @worker.work_off
            site = @current_user.sites.last
            site.last_invoice.reload.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_hash)
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
            fill_in "Domain", :with => "rymai.com"
            set_credit_card_in_site_form(type: 'master')
            VCR.use_cassette('ogone/master_payment_acceptance') { click_button "Create" }

            @worker.work_off
            site = @current_user.sites.last
            site.last_invoice.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_hash)
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
            fill_in "Domain", :with => "rymai.com"
            set_credit_card_in_site_form(d3d: true)
            VCR.use_cassette('ogone/visa_payment_acceptance_3ds') { click_button "Create" }
            @worker.work_off
            site = @current_user.sites.last
            transaction = site.last_invoice.last_transaction
            transaction.should be_waiting_d3d
            site.last_invoice.should be_open

            # fake payment succeeded callback (and thus skip the d3d redirection)
            transaction.process_payment_response("PAYID" => "1234", "NCSTATUS" => "3", "STATUS" => "2", "ORDERID" => transaction.id.to_s)
            transaction.reload.should be_failed
            site.reload.last_invoice.reload.should be_failed
            site.plan_id.should be_nil
            site.pending_plan_id.should == Plan.find_by_name_and_cycle("comet", "year").id
            site.first_paid_plan_started_at.should be_nil
            site.plan_started_at.should be_nil
            site.plan_cycle_started_at.should be_nil
            site.plan_cycle_ended_at.should be_nil
            site.pending_plan_started_at.should be_present
            site.pending_plan_cycle_started_at.should be_present
            site.pending_plan_cycle_ended_at.should be_present

            visit "/sites"
            
            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Site was successfully created.")
            page.should have_content('rymai.com')
            page.should have_content('Comet (yearly)')
            page.should have_no_selector('.usage_bar')
          end

          scenario "entering a 3-D Secure credit card with a succeeding identification" do
            fill_in "Domain", :with => "rymai.com"
            set_credit_card_in_site_form(d3d: true)
            VCR.use_cassette('ogone/visa_payment_acceptance_3ds') { click_button "Create" }
            @worker.work_off
            site = @current_user.sites.last
            transaction = site.last_invoice.last_transaction
            transaction.should be_waiting_d3d
            site.last_invoice.should be_open

            # fake payment succeeded callback (and thus skip the d3d redirection)
            transaction.process_payment_response("PAYID" => "1234", "NCSTATUS" => "0", "STATUS" => "9", "ORDERID" => transaction.id.to_s)
            transaction.reload.should be_paid
            
            site.reload.last_invoice.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_hash)
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
            page.should have_content("Site was successfully created.")
            page.should have_content('rymai.com')
            page.should have_content('Comet (yearly)')
            page.should have_selector('.usage_bar')
          end
        end # paid plan entering a credit card
      end

      describe "custom plan" do
        background do
          visit "/sites/new?custom_plan=#{Plan.find_by_name_and_cycle("custom1", "year").token}"
          choose "plan_custom"
        end

        context "entering no credit card" do
          scenario "with no hostname" do
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
            fill_in "Domain", :with => ""
            set_credit_card_in_site_form
            click_button "Create"

            current_url.should =~ %r(http://[^/]+/sites)
            page.should have_content("Domain can't be blank")
          end

          scenario "with a hostname" do
            fill_in "Domain", :with => "rymai.com"
            set_credit_card_in_site_form
            VCR.use_cassette('ogone/visa_payment_acceptance') { click_button "Create" }

            @worker.work_off
            site = @current_user.sites.last
            site.last_invoice.should be_paid
            site.hostname.should == "rymai.com"
            site.loader.read.should include(site.token)
            site.license.read.should include(site.license_hash)
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

  pending "with a user with a credit card registered" do
    background do
      sign_in_as :user, :without_cc => false
    end

    feature "new" do
      scenario "in dev plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => "google.com"
        choose "plan_dev"
        click_button "Create"

        @worker.work_off
        site = @current_user.sites.last
        site.hostname.should == "google.com"
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_hash)

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('google.com')
        page.should have_content('Sandbox')
      end

      pending "in custom plan"

      scenario "in paid plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => "google.com"
        choose "plan_comet_month"
        VCR.use_cassette('ogone/visa_payment_acceptance') { click_button "Create" }

        @worker.work_off
        site = @current_user.sites.last
        site.hostname.should == "google.com"
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_hash)

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('google.com')
        page.should have_content('Comet')
      end

      scenario "invalid in paid plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => ""
        choose "plan_comet_month"
        click_button "Create"

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content("Domain can't be blank")
      end
    end

    feature "edit" do
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

    feature "navigation" do
      scenario "new" do
        visit "/sites"
        click_link "Add a site"
        page.should have_content('Choose a plan for your site')
      end
    end

    feature "archive" do
      scenario "a dev site" do
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
    end

    feature "index" do
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