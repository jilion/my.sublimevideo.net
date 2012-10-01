require 'spec_helper'

feature "OAuth applications" do
  context "as a user without a @jilion.com email" do
    background do
      sign_in_as :user

      @application = create(:client_application, user: @current_user)
      @token       = create(:oauth2_token, user: @current_user, client_application: @application)
    end

    describe "list OAuth applications" do
      scenario "shows a list of applications" do
        go 'my', '/account/applications'
        current_url.should == "http://my.sublimevideo.dev/account"
      end
    end

    describe "new OAuth applications" do
      scenario "shows a list of applications" do
        go 'my', '/account/applications/new'
        current_url.should == "http://my.sublimevideo.dev/account"
      end
    end

    describe "edit an OAuth applications" do
      scenario "shows a list of applications" do
        go 'my', "/account/applications/#{@application.id}/edit"
        current_url.should == "http://my.sublimevideo.dev/account"
      end
    end
  end

  context "as a user with a @jilion.com email" do
    background do
      sign_in_as :user, email: "remy@jilion.com"

      @application = create(:client_application, user: @current_user)
      @token       = create(:oauth2_token, user: @current_user, client_application: @application)
    end

    describe "list OAuth applications" do
      scenario "shows a list of applications" do
        go 'my', '/account/applications'
        current_url.should == "http://my.sublimevideo.dev/account/applications"

        page.should have_content('Agree2')
      end
    end

    describe "new OAuth applications" do
      scenario "shows a list of applications" do
        go 'my', '/account/applications'

        click_link "Register a new application"
        current_url.should == "http://my.sublimevideo.dev/account/applications/new"

        fill_in "Name", with: "WordPress"
        fill_in "Url", with: "http://wordpress.com"
        click_button "Register"

        current_url.should == "http://my.sublimevideo.dev/account/applications/#{ClientApplication.last.id}"
        page.should have_content('WordPress')
      end
    end

    describe "edit an OAuth applications" do
      scenario "shows a list of applications" do
        go 'my', '/account/applications'

        click_link "Edit"

        current_url.should == "http://my.sublimevideo.dev/account/applications/#{@application.id}/edit"
        page.should have_content("Edit the application 'Agree2'")

        fill_in "Name", with: "Agree3"
        fill_in "Callback url", with: "http://test.fr"
        click_button "Update"

        page.should have_content('Agree3')
        page.should have_content('http://test.com')
        page.should have_content('http://test.fr')
      end
    end

    # Failure/Error: fill_in "Password", with: "123456"
    # cannot fill in, no text field, text area or password field with id, name, or label 'Password' found
    describe "delete an OAuth applications" do
      scenario "shows a list of applications" do
        go 'my', '/account/applications'
        page.should have_content('Agree2')

        click_button "Delete"

        current_url.should =~ %r(^http://[^/]+/account/applications$)
        page.should have_no_content('Agree2')
      end
    end
  end

end
