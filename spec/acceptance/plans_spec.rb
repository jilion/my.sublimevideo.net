require 'spec_helper'

feature "Plans" do
  background do
    sign_in_as :user
  end

  feature "edit" do

    scenario "update paid plan to dev plan" do
      site = Factory(:site, user: @current_user, plan: @paid_plan)

      visit edit_site_plan_path(site)

      page.should have_content("Your current plan, #{site.plan.title}, will be automatically renewed on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")

      choose "plan_dev"
      click_button "Update plan"

      fill_in "Password", :with => "123456"
      click_button "Done"
      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      page.should have_content("Your current plan, #{site.plan.title}, will end on #{I18n.l site.plan_cycle_ended_at, :format => :named_date}")
      page.should have_content("Your next plan, #{site.next_cycle_plan.title}, will automatically start on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")
    end

    scenario "update dev plan to paid plan" do
      @paid_plan.reload.update_attribute(:name, 'small')
      site = Factory(:site, user: @current_user, plan: @dev_plan)

      visit edit_site_plan_path(site)

      page.should have_content("You are currently using the unlimited free development plan")

      choose "plan_small_month"
      click_button "Update plan"
      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title}")

      click_link site.plan.title

      page.should have_content("Your current plan, #{site.plan.title}, will be automatically renewed on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")
    end

    scenario "cancel next plan automatic update" do
      @paid_plan.reload.update_attribute(:name, 'small')
      site = Factory(:site, user: @current_user, plan: @paid_plan)

      site.update_attribute(:next_cycle_plan_id, @dev_plan.id)

      visit sites_path

      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
      page.should have_content("Your current plan, #{site.plan.title}, will end on #{I18n.l site.plan_cycle_ended_at, :format => :named_date}")
      page.should have_content("Your next plan, #{site.next_cycle_plan.title}, will automatically start on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")

      click_button "cancel"

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should_not have_content("#{site.plan.title} => ")
      page.should have_content(site.plan.title)

      click_link site.plan.title

      page.should have_content("Your current plan, #{site.plan.title}, will be automatically renewed on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")
    end

    pending "update paid plan to paid plan with credit card data"

  end

end
