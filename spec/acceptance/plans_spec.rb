require 'spec_helper'

feature "Plans" do
  background do
    sign_in_as :user
  end

  # WAITING FOR OCTAVE TO FINISH THE PAGE
  feature "edit" do

    pending "update paid plan to dev plan" do
      site = Factory(:site, user: @current_user, plan: @paid_plan)

      visit "/sites/#{site.token}/plan/edit"

      choose "plan_dev"
      click_button "Update plan"

      save_and_open_page

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content('Dev')
    end

  end

end
