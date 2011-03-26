require 'spec_helper'

feature "Plans" do
  background do
    sign_in_as :user
  end

  feature "edit" do

    scenario "update paid plan to dev plan" do
      site = Factory(:site, user: @current_user, plan_id: @paid_plan.id)

      visit edit_site_plan_path(site)

      choose "plan_dev"
      click_button "Update plan"

      has_checked_field?("plan_dev").should be_true
      has_unchecked_field?("plan_comet_month").should be_true

      fill_in "Password", :with => "123456"
      click_button "Done"

      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      page.should have_content("Your new plan #{site.next_cycle_plan.title} will automatically start on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}.")
    end

    # TODO Rémy
    pending "update paid plan to paid plan with credit card data"

    scenario "failed update" do
      site = Factory(:site, user: @current_user, plan_id: @dev_plan.id)

      visit edit_site_plan_path(site)

      VCR.use_cassette('ogone/visa_payment_generic_failed') do
        choose "plan_comet_month"
        click_button "Update plan"
      end

      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)

      page.should_not have_content("Choose a plan")
      page.should have_content("#{site.plan.title}")
      page.should have_content(I18n.t('site.status.payment_issue'))

      visit edit_site_plan_path(site)

      page.should_not have_content("Comet")
      page.should have_content("There has been a transaction error. Please review")
    end

    scenario "update dev plan to paid plan" do
      site = Factory(:site, user: @current_user, plan_id: @dev_plan.id)

      visit edit_site_plan_path(site)

      VCR.use_cassette('ogone/visa_payment_generic') do
        choose "plan_comet_month"
        click_button "Update plan"
      end

      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title}")

      click_link site.plan.title
    end

    scenario "cancel next plan automatic update" do
      site = Factory(:site, user: @current_user, plan_id: @paid_plan.id)

      site.update_attribute(:next_cycle_plan_id, @dev_plan.id)

      visit sites_path

      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
      page.should have_content("Your new plan #{site.next_cycle_plan.title} will automatically start on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}.")

      click_button "Cancel"

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should_not have_content("#{site.plan.title} => ")
      page.should have_content(site.plan.title)

      click_link site.plan.title
    end

  end

  feature "sponsored plan" do

    scenario "view" do
      site = Factory(:site, user: @current_user)
      site.sponsor!
      Factory(:site_usage, site_id: site.id, day: Time.now.utc, main_player_hits: 1000)

      visit sites_path

      page.should have_content("Sponsored")
      page.should have_content("1,000 Sponsored hits")

      click_link "Sponsored"

      page.should have_content("Your plan is currently sponsored by Jilion.")
      page.should have_content("If you have any questions, please contact us.")
    end

  end

  feature "custom plan" do

    scenario "add a new site" do
      visit new_site_path(custom_plan: @custom_plan.token)

      VCR.use_cassette('ogone/visa_payment_generic') do
        choose "plan_custom"
        fill_in "Domain", :with => "google.com"
        click_button "Create"
      end

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content('google.com')
      page.should have_content(@custom_plan.title)
    end

    scenario "view" do
      site = Factory(:site, user: @current_user, plan_id: @custom_plan.token)

      visit sites_path

      click_link "Custom"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
      page.should have_content(@custom_plan.title)
    end

    scenario "upgrade site" do
      site = Factory(:site, user: @current_user, plan_id: @paid_plan.id)

      visit edit_site_plan_path(site, custom_plan: @custom_plan.token)

      choose "plan_custom"
      click_button "Update plan"

      has_checked_field?("plan_custom").should be_true

      VCR.use_cassette('ogone/visa_payment_generic') do
        fill_in "Password", :with => "123456"
        click_button "Done"
      end

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content(@custom_plan.title)
    end

  end
end
