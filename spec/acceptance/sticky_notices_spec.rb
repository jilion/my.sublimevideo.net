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
      sign_in_as :user, :cc_expire_on => Time.now.utc
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
      sign_in_as :user, :cc_expire_on => 2.month.ago
    end

    scenario "show a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your credit card is expired")
    end
  end

  feature "user will be suspended" do
    background do
      sign_in_as :user, :suspend => true
    end

    scenario "show a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your account will be suspended in")
    end
  end

  feature "user will be suspended and credit card will expire this month" do
    background do
      sign_in_as :user, :suspend => true, :cc_expire_on => Time.now.utc
    end

    scenario "show a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your account will be suspended in")
    end
  end

  feature "user will be suspended and credit card is expired" do
    background do
      sign_in_as :user, :suspend => true, :cc_expire_on => 2.month.ago
    end

    scenario "show a notice" do
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("Your account will be suspended in")
    end
  end
  
  feature "user have beta sites" do
    background do
      sign_in_as :user
    end

    scenario "show a notice" do
      Factory(:site, :user => @current_user, :state => "beta")
      PublicLaunch.stub(:beta_transition_ended_on) { 12.days.from_now.to_date }
      visit '/sites'

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content("12 days left to choose a plan for your beta sites")
      Timecop.return
    end
  end
end