require 'spec_helper'

feature "Sticky notices" do
  context "no notice" do
    background do
      sign_in_as :user, kill_user: true
      Factory.create(:site, user: @current_user)
    end

    scenario "no notice" do
      visit '/sites'

      current_url.should =~ %r(^http://[^/]+/sites$)
      page.should have_no_content("Your credit card will expire at the end of this month")
      page.should have_no_content("Your credit card is expired.")
      page.should have_no_content("update it")
    end
  end

  context "credit card will expire this month" do
    background do
      sign_in_as :user, cc_expire_on: Time.utc(Time.now.utc.year, Time.now.utc.month).end_of_month.to_date, kill_user: true
      @current_user.should be_cc_expire_this_month
    end

    context "user is not billable" do
      scenario "doesn't show a notice" do
        @current_user.should_not be_billable
        visit '/sites'

        current_url.should =~ %r(^http://[^/]+/sites/new$)
        page.should have_no_content("Your credit card will expire at the end of this month")
      end
    end

    context "user is billable" do
      background do
        Factory.create(:site, user: @current_user)
        @current_user.should be_billable
      end

      scenario "shows a notice" do
        visit '/sites'

        current_url.should =~ %r(^http://[^/]+/sites$)
        page.should have_content("Your credit card will expire at the end of this month")
        page.should have_content("update it")
      end
    end
  end

  context "credit card is expired" do
    background do
      sign_in_as :user, cc_expire_on: 2.years.ago, kill_user: true
      @site = Factory.create(:site, user: @current_user)
    end

    scenario "shows a notice" do
      visit '/sites'

      current_url.should =~ %r(^http://[^/]+/sites$)
      page.should have_content("Your credit card is expired")
    end
  end

end
