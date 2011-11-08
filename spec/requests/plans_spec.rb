require 'spec_helper'

feature "edit" do
  background do
    sign_in_as :user
    @gold_month = Plan.create(name: "gold", cycle: "month", video_views: 200_000, price: 4990)
    @gold_year = Plan.create(name: "gold", cycle: "year", video_views: 200_000, price: 49900)
  end

  context "site in trial" do
    scenario "view with a free plan without hostname" do
      site = Factory.create(:site, user: @current_user, plan_id: @free_plan.id, hostname: nil)

      visit edit_site_plan_path(site)

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
      page.should have_content("add a hostname")
    end

    scenario "update paid plan to free plan" do
      site = Factory.create(:site, user: @current_user, plan_id: @paid_plan.id)

      visit edit_site_plan_path(site)

      choose "plan_free"
      has_checked_field?("plan_free").should be_true
      has_unchecked_field?("plan_silver_month").should be_true
      click_button "Update plan"

      site.reload
      site.plan.should eql @free_plan

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content(site.plan.title)
    end

    scenario "update free plan to paid plan" do
      site = Factory.create(:site, user: @current_user, plan_id: @free_plan.id)

      visit edit_site_plan_path(site)

      choose "plan_silver_month"
      click_button "Update plan"

      site.reload
      site.plan.should eql @paid_plan

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content(site.plan.title)
    end
  end

  context "site not in trial" do
    scenario "view with a free plan without hostname" do
      site = Factory.create(:site_not_in_trial, user: @current_user, plan_id: @free_plan.id, hostname: nil)

      visit edit_site_plan_path(site)

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
      page.should have_content("add a hostname")
    end

    scenario "update paid plan to free plan" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

      visit edit_site_plan_path(site)

      choose "plan_free"
      click_button "Update plan"

      has_checked_field?("plan_free").should be_true
      has_unchecked_field?("plan_silver_month").should be_true

      fill_in "Password", with: "123456"
      click_button "Done"

      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      page.should have_content("Your new <strong>#{site.next_cycle_plan.title}</strong> plan will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, format: :named_date).squeeze(' ')}.")
    end

    scenario "update free plan to paid plan" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @gold_month.id)
      site.plan_id = @free_plan.id
      site.save_without_password_validation
      Timecop.travel(2.months.from_now) { site.pend_plan_changes; site.apply_pending_plan_changes }
      site.reload.plan.should eql @free_plan

      visit edit_site_plan_path(site)

      VCR.use_cassette('ogone/visa_payment_generic') do
        choose "plan_silver_month"
        click_button "Update plan"
      end

      site.reload.plan.should eql @paid_plan

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content(site.plan.title)

      click_link site.plan.title
    end

    scenario "update paid plan to paid plan with credit card data" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @gold_month.id)
      site.plan.should eql @gold_month
      site.first_paid_plan_started_at.should be_present
      site.plan_started_at.should be_present
      site.plan_cycle_started_at.should be_present
      site.plan_cycle_ended_at.should be_present

      visit edit_site_plan_path(site)

      page.should have_no_selector("#credit_card")
      page.should have_selector("#credit_card_summary")

      choose "plan_gold_year"

      has_checked_field?("plan_gold_year").should be_true
      click_button "Update plan"

      VCR.use_cassette('ogone/visa_payment_generic') do
        fill_in "Password", with: "123456"
        click_button "Done"
      end

      site.reload.plan.should eql @gold_year

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title}")

      click_link "#{site.plan.title}"
      has_checked_field?("plan_gold_year").should be_true
    end

    scenario "update paid plan to paid plan without credit card data" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @gold_month.id)
      site.plan.should eql @gold_month
      site.first_paid_plan_started_at.should be_present
      site.plan_started_at.should be_present
      site.plan_cycle_started_at.should be_present
      site.plan_cycle_ended_at.should be_present
      @current_user.update_attribute(:cc_expire_on, 2.month.ago.end_of_month)
      @current_user.cc_expire_on.should eql 2.month.ago.end_of_month

      visit edit_site_plan_path(site)

      page.should have_selector("#credit_card")
      page.should have_no_selector("#credit_card_summary")

      choose "plan_gold_year"
      set_credit_card
      has_checked_field?("plan_gold_year").should be_true

      click_button "Update plan"

      VCR.use_cassette('ogone/visa_payment_generic') do
        fill_in "Password", with: "123456"
        click_button "Done"
      end

      site.reload.plan.should eql @gold_year

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content(site.plan.title)

      click_link site.plan.title
      has_checked_field?("plan_gold_year").should be_true
    end

    scenario "failed update" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @free_plan.id)

      visit edit_site_plan_path(site)

      VCR.use_cassette('ogone/visa_payment_generic_failed') do
        choose "plan_silver_month"
        click_button "Update plan"
      end

      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)

      page.should have_content("Embed Code")
      page.should have_content(site.plan.title)
      page.should have_content(I18n.t('site.status.payment_issue'))

      visit edit_site_plan_path(site)

      page.should_not have_content(site.plan.title)
      page.should have_content("There has been a transaction error. Please review")
    end

    scenario "cancel next plan automatic update" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

      site.update_attribute(:next_cycle_plan_id, @free_plan.id)

      visit sites_path

      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)

      page.should have_content("Your new <strong>#{site.next_cycle_plan.title}</strong> plan will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, format: :named_date).squeeze(' ')}.")

      click_button "Cancel"

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should_not have_content("#{site.plan.title} => ")
      page.should have_content(site.plan.title)

      click_link site.plan.title
    end
  end
end

feature "sponsored plan" do
  background do
    sign_in_as :user
  end

  scenario "view" do
    site = Factory.create(:site, user: @current_user, last_30_days_main_video_views: 1000, last_30_days_extra_video_views: 500)
    site.sponsor!

    visit sites_path

    page.should have_content("Sponsored")
    page.should have_content("1,500 sponsored video views")

    click_link "Sponsored"

    page.should have_content("Your plan is currently sponsored by Jilion.")
    page.should have_content("If you have any questions, please contact us.")
  end
end

feature "custom plan" do
  background do
    sign_in_as :user
  end

  scenario "add a new site" do
    visit new_site_path(custom_plan: @custom_plan.token)

    VCR.use_cassette('ogone/visa_payment_generic') do
      choose "plan_custom"
      fill_in "Domain", with: "google.com"
      click_button "Create"
    end

    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')
    page.should have_content(@custom_plan.title)
  end

  scenario "view" do
    site = Factory.create(:site, user: @current_user, plan_id: @custom_plan.token)

    visit sites_path

    click_link "Custom"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
    page.should have_content(@custom_plan.title)
  end

  scenario "upgrade site" do
    site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

    visit edit_site_plan_path(site, custom_plan: @custom_plan.token)

    choose "plan_custom"
    has_checked_field?("plan_custom").should be_true
    click_button "Update plan"

    VCR.use_cassette('ogone/visa_payment_generic') do
      fill_in "Password", with: "123456"
      click_button "Done"
    end

    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content(@custom_plan.title)
  end
end
