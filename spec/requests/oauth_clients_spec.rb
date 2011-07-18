require 'spec_helper'

feature "OAuth applications" do
  background do
    sign_in_as :user

    @application = Factory(:client_application, user: @current_user)
    @token       = Factory(:oauth2_token, user: @current_user, client_application: @application)
  end

  describe "list OAuth applications" do
    scenario "shows a list of applications" do
      visit "/account/applications"
      current_url.should =~ %r(^http://[^/]+/account/applications$)

      page.should have_content('Agree2')
    end
  end

  describe "new OAuth applications" do
    scenario "shows a list of applications" do
      visit "/account/applications"
      current_url.should =~ %r(^http://[^/]+/account/applications$)

      click_link "Register a new application"
      current_url.should =~ %r(^http://[^/]+/account/applications/new$)

      fill_in "Name", :with => "WordPress"
      fill_in "Url", :with => "http://wordpress.com"
      click_button "Register"

      current_url.should =~ %r(^http://[^/]+/account/applications/#{ClientApplication.last.id}$)
      page.should have_content('WordPress')
    end
  end

  describe "edit an OAuth applications" do
    scenario "shows a list of applications" do
      visit "/account/applications"
      current_url.should =~ %r(^http://[^/]+/account/applications$)

      click_link "Edit"

      current_url.should =~ %r(^http://[^/]+/account/applications/#{@application.id}/edit$)
      page.should have_content('Agree2')
    end
  end

end
