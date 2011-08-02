require 'spec_helper'

feature "edit" do
  background do
    sign_in_as :user
    @star_month = Plan.create(name: "star", cycle: "month", player_hits: 200_000, price: 4990)
    @star_year = Plan.create(name: "star", cycle: "year", player_hits: 200_000, price: 49900)
  end

  scenario "view with a dev plan without hostname" do
    site = FactoryGirl.create(:site, user: @current_user, plan_id: @dev_plan.id, :hostname => nil)

    visit edit_site_plan_path(site)

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
    page.should have_content("add a hostname")
  end

  scenario "update paid plan to dev plan" do
    site = FactoryGirl.create(:site, user: @current_user, plan_id: @paid_plan.id)

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

    page.should have_content("Your new plan #{site.next_cycle_plan.title} will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date).squeeze(' ')}.")
  end

  scenario "update paid plan to paid plan with credit card data" do
    site = FactoryGirl.create(:site_with_invoice, user: @current_user, plan_id: @star_month.id)
    site.plan.should == @star_month
    site.first_paid_plan_started_at.should be_present
    site.plan_started_at.should be_present
    site.plan_cycle_started_at.should be_present
    site.plan_cycle_ended_at.should be_present

    visit edit_site_plan_path(site)

    page.should have_no_selector("#credit_card")
    page.should have_selector("#credit_card_summary")

    choose "plan_star_year"

    has_checked_field?("plan_star_year").should be_true
    click_button "Update plan"

    VCR.use_cassette('ogone/visa_payment_generic') do
      fill_in "Password", :with => "123456"
      click_button "Done"
    end

    site.reload
    site.plan.should == @star_year

    current_url.should =~ %r(http://[^/]+/sites$)
    page.should have_content("#{site.plan.title}")

    click_link "#{site.plan.title}"
    has_checked_field?("plan_star_year").should be_true
  end

  scenario "update paid plan to paid plan without credit card data" do
    site = FactoryGirl.create(:site_with_invoice, user: @current_user, plan_id: @star_month.id)
    site.plan.should == @star_month
    site.first_paid_plan_started_at.should be_present
    site.plan_started_at.should be_present
    site.plan_cycle_started_at.should be_present
    site.plan_cycle_ended_at.should be_present
    @current_user.update_attribute(:cc_expire_on, 2.month.ago.end_of_month)
    @current_user.cc_expire_on.should == 2.month.ago.end_of_month

    visit edit_site_plan_path(site)

    page.should have_selector("#credit_card")
    page.should have_no_selector("#credit_card_summary")

    choose "plan_star_year"
    set_credit_card
    has_checked_field?("plan_star_year").should be_true

    click_button "Update plan"

    VCR.use_cassette('ogone/visa_payment_generic') do
      fill_in "Password", :with => "123456"
      click_button "Done"
    end

    site.reload
    site.plan.should == @star_year

    current_url.should =~ %r(http://[^/]+/sites$)
    page.should have_content("#{site.plan.title}")

    click_link "#{site.plan.title}"
    has_checked_field?("plan_star_year").should be_true
  end

  scenario "failed update" do
    site = FactoryGirl.create(:site, user: @current_user, plan_id: @dev_plan.id)

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
    site = FactoryGirl.create(:site, user: @current_user, plan_id: @dev_plan.id)

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
    site = FactoryGirl.create(:site, user: @current_user, plan_id: @paid_plan.id)

    site.update_attribute(:next_cycle_plan_id, @dev_plan.id)

    visit sites_path

    page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

    click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)

    page.should have_content("Your new plan #{site.next_cycle_plan.title} will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date).squeeze(' ')}.")

    click_button "Cancel"

    current_url.should =~ %r(http://[^/]+/sites$)
    page.should_not have_content("#{site.plan.title} => ")
    page.should have_content(site.plan.title)

    click_link site.plan.title
  end

end

feature "sponsored plan" do
  background do
    sign_in_as :user
  end

  scenario "view" do
    site = FactoryGirl.create(:site, user: @current_user)
    site.sponsor!
    FactoryGirl.create(:site_usage, site_id: site.id, day: Time.now.utc, main_player_hits: 1000)

    visit sites_path

    page.should have_content("Sponsored")
    page.should have_content("1,000 sponsored video pageviews")

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
      fill_in "Domain", :with => "google.com"
      click_button "Create"
    end

    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('google.com')
    page.should have_content(@custom_plan.title)
  end

  scenario "view" do
    site = FactoryGirl.create(:site, user: @current_user, plan_id: @custom_plan.token)

    visit sites_path

    click_link "Custom"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
    page.should have_content(@custom_plan.title)
  end

  scenario "upgrade site" do
    site = FactoryGirl.create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

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
