require 'spec_helper'

feature "Sticky notices" do
  context "no notice" do
    background do
      sign_in_as :user
    end

    scenario "no notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should_not have_content("Your credit card will expire at the end of the month")
      page.should_not have_content("Your credit card is expired.")
      page.should_not have_content("update it")
    end
  end

  context "credit card will expire this month but user is not billable" do
    background do
      sign_in_as :user
      @current_user.update_attribute(:cc_expire_on, Time.now.utc.end_of_month)
      @current_user.cc_expire_on.should == Time.now.utc.end_of_month
    end

    scenario "doesn't show a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should_not have_content("Your credit card will expire at the end of the month")
      page.should_not have_content("update it")
    end
  end

  context "credit card will expire this month" do
    background do
      sign_in_as :user
      @current_user.update_attribute(:cc_expire_on, Time.now.utc.end_of_month)
      @current_user.cc_expire_on.should == Time.now.utc.end_of_month
      @site = FactoryGirl.create(:site, user: @current_user)
    end

    scenario "shows a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your credit card will expire at the end of the month")
      page.should have_content("update it")
    end
  end

  context "credit card is expired" do
    background do
      sign_in_as :user
      @current_user.update_attribute(:cc_expire_on, 2.month.ago.end_of_month)
      @current_user.cc_expire_on.should == 2.month.ago.end_of_month
      @site = FactoryGirl.create(:site, user: @current_user)
    end

    scenario "shows a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your credit card is expired")
    end
  end

end
