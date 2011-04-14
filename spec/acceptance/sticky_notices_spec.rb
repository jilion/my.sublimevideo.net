require 'spec_helper'

feature "Sticky notices" do
  feature "no notice" do
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

  feature "credit card will expire this month" do
    background do
      sign_in_as :user
      @current_user.update_attribute(:cc_expire_on, Time.now.utc.end_of_month)
      @current_user.cc_expire_on.should == Time.now.utc.end_of_month
    end

    scenario "show a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your credit card will expire at the end of the month")
      page.should have_content("update it")
    end
  end

  feature "credit card is expired" do
    background do
      sign_in_as :user
      @current_user.update_attribute(:cc_expire_on, 2.month.ago.end_of_month)
      @current_user.cc_expire_on.should == 2.month.ago.end_of_month
    end

    scenario "show a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your credit card is expired")
    end
  end

  feature "user have beta sites" do
    context "more than 2 days before the end of the beta" do
      background do
        sign_in_as :user
        Timecop.travel(PublicLaunch.beta_transition_ended_on - 12.days + 1.hour)
      end

      scenario "show a notice" do
        Factory(:site, user: @current_user, plan_id: @beta_plan.id)
        visit '/sites'

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content("11 days left to choose a plan for your sites")
        Timecop.return
      end
    end

    context "less than 2 days before the end of the beta" do
      background do
        sign_in_as :user
        Timecop.travel(PublicLaunch.beta_transition_ended_on - 2.days + 1.hour)
      end

      scenario "show a notice" do
        Factory(:site, user: @current_user, plan_id: @beta_plan.id)
        visit '/sites'

        current_url.should =~ %r(http://[^/]+/sites)
        page.should have_content("46 hours left to choose a plan for your sites")
        Timecop.return
      end
    end
  end

  feature "when invitation redirect to signup" do

    scenario "show beta is finished notice" do
      VCR.use_cassette("twitter/signup") { visit '/invitation/accept?invitation_token=xxx' }
      current_url.should =~ %r(http://[^/]+/signup\?beta=over$)

      page.should have_content("We have now launched publicly!")
      page.should have_content("The Beta period is over. Please check out our new")
    end

  end

end