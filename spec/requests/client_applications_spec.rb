require 'spec_helper'

feature "OAuth applications" do
  context "as a user without a @jilion.com email" do
    background do
      sign_in_as :user

      @application = Factory(:client_application, user: @current_user)
      @token       = Factory(:oauth2_token, user: @current_user, client_application: @application)
    end

    describe "list OAuth applications" do
      scenario "shows a list of applications" do
        visit "/account/applications"
        current_url.should =~ %r(^http://[^/]+/account/edit$)
      end
    end

    describe "new OAuth applications" do
      scenario "shows a list of applications" do
        visit "/account/applications/new"
        current_url.should =~ %r(^http://[^/]+/account/edit$)
      end
    end

    describe "edit an OAuth applications" do
      scenario "shows a list of applications" do
        visit "/account/applications/#{@application.id}/edit"
        current_url.should =~ %r(^http://[^/]+/account/edit$)
      end
    end
  end

  context "as a user with a @jilion.com email" do
    background do
      sign_in_as :user, email: "remy@jilion.com"

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
        page.should have_content('Edit the application')
        page.should have_content('Agree2')
      end
    end

    # Failure/Error: fill_in "Password", :with => "123456"
    # cannot fill in, no text field, text area or password field with id, name, or label 'Password' found
    pending "delete an OAuth applications" do
      scenario "shows a list of applications" do
        visit "/account/applications"
        current_url.should =~ %r(^http://[^/]+/account/applications$)
        page.should have_content('Agree2')

        click_button "Delete"

        fill_in "Password", :with => "123456"
        click_button "Done"

        current_url.should =~ %r(^http://[^/]+/account/applications$)
        page.should have_no_content('Agree2')
      end
    end
  end

end
