require 'spec_helper'

feature "Sites" do

  context "with a user with no credit card registered" do
    background do
      sign_in_as :user, :without_cc => true
    end

    feature "new" do
      scenario "in dev plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => "google.com"
        choose "plan_dev"
        click_button "Create"

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('google.com')
        page.should have_content('Sandbox')

        @worker.work_off
        site = @current_user.sites.last
        site.hostname.should == "google.com"
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_json)
      end

      pending "in custom plan"

      pending "in paid plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => "rymai.com"
        choose "plan_comet_month"
        VCR.use_cassette('ogone/visa_payment_10') { click_button "Create" }

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content("You need a valid credit card to choose this plan")
      end

      scenario "invalid in paid plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => ""
        choose "plan_comet_month"
        click_button "Create"

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('Please set at least one domain')
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

  context "with a user with a credit card registered" do
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

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('google.com')
        page.should have_content('Sandbox')

        @worker.work_off
        site = @current_user.sites.last
        site.hostname.should == "google.com"
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_json)
      end

      pending "in custom plan"

      scenario "in paid plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => "google.com"
        choose "plan_comet_month"
        VCR.use_cassette('ogone/visa_payment_10') { click_button "Create" }

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('google.com')
        page.should have_content('Comet')

        @worker.work_off
        site = @current_user.sites.last
        site.hostname.should == "google.com"
        site.loader.read.should include(site.token)
        site.license.read.should include(site.license_json)
      end

      scenario "invalid in paid plan" do
        visit "/sites"
        click_link "Add a site"

        fill_in "Domain", :with => ""
        choose "plan_comet_month"
        click_button "Create"

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content('Please set at least one domain')
      end
    end

    scenario "user suspended" do
      @current_user.suspend
      visit "/sites"

      current_url.should =~ %r(http://[^/]+/suspended)
    end
  end

  context "no matter if the user has a credit card or not" do
    background do
      sign_in_as :user
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