require 'spec_helper'

feature "Plans" do
  background do
    sign_in_as :user
  end

  feature "edit" do

    scenario "update paid plan to dev plan" do
      site = Factory(:site, user: @current_user, plan: @paid_plan)

      visit "/sites/#{site.token}/plan/edit"

      choose "plan_dev"
      click_button "Update plan"

      fill_in "Password", :with => "123456"
      click_button "Done"

      current_url.should =~ %r(http://[^/]+/sites$)
      page.should have_content('Dev')
    end

    scenario "update dev plan to paid plan" do
      site = Factory(:site, user: @current_user, plan: @dev_plan)
      @paid_plan.update_attribute(:name, 'small')

      visit "/sites/#{site.token}/plan/edit"

      choose "plan_small"
      click_button "Update plan"

      current_url.should =~ %r(http://[^/]+/sites$)

      page.should have_content('Small')
    end

    pending "Update paid plan to paid plan with credit card data"

  end

end
