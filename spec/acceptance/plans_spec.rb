require 'spec_helper'

feature "Plans" do
  background do
    sign_in_as :user
  end

  feature "edit" do

    scenario "update paid plan to dev plan" do
      site = Factory(:site, user: @current_user, plan_id: @paid_plan.id)

      visit edit_site_plan_path(site)

      #page.should have_content("Your current plan, #{site.plan.title}, will be automatically renewed on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")

      choose "plan_dev"
      click_button "Update plan"

      fill_in "Password", :with => "123456"
      click_button "Done"
      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      #page.should have_content("Your current plan, #{site.plan.title}, will end on #{I18n.l site.plan_cycle_ended_at, :format => :named_date}")
      page.should have_content("Your new plan #{site.next_cycle_plan.title} will automatically start on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}.")
    end

    # TODO Rémy
    pending "update paid plan to paid plan with credit card data"

    # TODO Rémy, password should not be needed  dev => paid
    pending "update dev plan to paid plan" do
      site = Factory(:site, user: @current_user, plan_id: @dev_plan.id)

      visit edit_site_plan_path(site)

      #page.should have_content("You are currently using the unlimited free development plan")

      choose "plan_comet_month"
      click_button "Update plan"

      site.reload

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content("#{site.plan.title}")

      click_link site.plan.title

      #page.should have_content("Your current plan, #{site.plan.title}, will be automatically renewed on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")
    end

    scenario "cancel next plan automatic update" do
      @paid_plan.reload.update_attribute(:name, 'small')
      site = Factory(:site, user: @current_user, plan_id: @paid_plan.id)

      site.update_attribute(:next_cycle_plan_id, @dev_plan.id)

      visit sites_path

      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
      #page.should have_content("Your current plan, #{site.plan.title}, will end on #{I18n.l site.plan_cycle_ended_at, :format => :named_date}")
      page.should have_content("Your new plan #{site.next_cycle_plan.title} will automatically start on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}.")

      click_button "Cancel"

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should_not have_content("#{site.plan.title} => ")
      page.should have_content(site.plan.title)

      click_link site.plan.title

      #page.should have_content("Your current plan, #{site.plan.title}, will be automatically renewed on #{I18n.l site.plan_cycle_ended_at.tomorrow.midnight, :format => :named_date}")
    end

    # TODO Thibaud
    scenario "sponsored plan" do
      site = Factory(:site, user: @current_user, plan_id: @sponsored_plan.id)
      Factory(:site_usage, site_id: site.id, day: Time.now.utc, main_player_hits: 1000)

      visit sites_path

      page.should have_content("Sponsored")
      page.should have_content("1,000 Sponsored hits")

      click_link "Sponsored"

      page.should have_content("Your plan are currently sponsored by Jilion.")
      page.should have_content("If you have any questions, please contact us.")
    end

    pending "update paid plan to paid plan with credit card data"

  end

end
