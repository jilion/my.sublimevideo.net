# coding: utf-8
require 'spec_helper'

feature "Users" do

  describe "sign-up redirections" do
    scenario "redirect /register to /signup" do
      VCR.use_cassette("twitter/signup") { visit "/register" }
      current_url.should =~ %r(^http://[^/]+/signup$)
    end

    scenario "redirect /sign_up to /signup" do
      VCR.use_cassette("twitter/signup") { visit "/sign_up" }
      current_url.should =~ %r(^http://[^/]+/signup$)
    end
  end

  describe "log-in redirections" do
    scenario "redirect /log_in to /login" do
      visit "/log_in"
      current_url.should =~ %r(^http://[^/]+/login$)
    end

    scenario "redirect /sign_in to /login" do
      visit "/sign_in"
      current_url.should =~ %r(^http://[^/]+/login$)
    end

    scenario "redirect /signin to /login" do
      visit "/signin"
      current_url.should =~ %r(^http://[^/]+/login$)
    end
  end

  context "logged-in user" do
    background do
      sign_in_as :user
    end

    describe "log-out redirections" do
      scenario "redirect /log_out to /logout" do
        page.should have_content @current_user.full_name
        visit "/log_out"
        page.should have_no_content @current_user.full_name
      end

      scenario "redirect /sign_out to /logout" do
        page.should have_content @current_user.full_name
        visit "/sign_out"
        page.should have_no_content @current_user.full_name
      end

      scenario "redirect /signout to /logout" do
        page.should have_content @current_user.full_name
        visit "/signout"
        page.should have_no_content @current_user.full_name
      end
    end
  end

  describe "signup" do
    before(:each) do
      VCR.use_cassette("twitter/signup") { visit "/signup" }
      current_url.should =~ %r(^http://[^/]+/signup$)
    end

    describe "signup for personal use" do
      scenario "with all fields needed" do
        fill_in "Email",              :with => "remy@jilion.com"
        fill_in "Password",           :with => "123456"
        fill_in "First name",         :with => "Rémy"
        fill_in "Last name",          :with => "Coutable"
        select "Switzerland",         :from => "Country"
        fill_in "Zip or Postal Code", :with => "CH-1024"
        check "Personal"
        check "user_terms_and_conditions"
        click_button "Sign Up"

        current_url.should =~ %r(^http://[^/]+/sites/new$)
        page.should have_content "Rémy Coutable"

        User.last.full_name.should == "Rémy Coutable"
        User.last.email.should == "remy@jilion.com"
      end

      scenario "with errors" do
        fill_in "Email",              :with => ""
        fill_in "Password",           :with => ""
        fill_in "First name",         :with => ""
        fill_in "Last name",          :with => ""
        fill_in "Zip or Postal Code", :with => ""
        VCR.use_cassette("twitter/signup") { click_button "Sign Up" }

        current_url.should =~ %r(^http://[^/]+/signup$)
        page.should have_content "Email can't be blank"
        page.should have_content "Password can't be blank"
        page.should have_content "First name can't be blank"
        page.should have_content "Last name can't be blank"
        page.should have_content "Postal code can't be blank"
        page.should have_content "Terms & Conditions must be accepted"
      end
    end

    describe "signup for company use" do
      scenario "with all fields needed" do
        fill_in "Email",              :with => "remy@jilion.com"
        fill_in "Password",           :with => "123456"
        fill_in "First name",         :with => "Rémy"
        fill_in "Last name",          :with => "Coutable"
        select  "Switzerland",        :from => "Country"
        fill_in "Zip or Postal Code", :with => "CH-1024"
        fill_in "Company name",       :with => "Jilion"
        select  "21-100 employees",   :from => "Company size"
        check   "For my company"
        check   "user_terms_and_conditions"
        click_button "Sign Up"

        current_url.should =~ %r(^http://[^/]+/sites/new$)
        page.should have_content "Rémy Coutable"

        User.last.full_name.should == "Rémy Coutable"
        User.last.email.should == "remy@jilion.com"
      end

      scenario "with optional blank fields" do
        fill_in "Email",              :with => "remy@jilion.com"
        fill_in "Password",           :with => "123456"
        fill_in "First name",         :with => "Rémy"
        fill_in "Last name",          :with => "Coutable"
        select  "Switzerland",        :from => "Country"
        fill_in "Zip or Postal Code", :with => "CH-1024"
        fill_in "Company name",       :with => ""
        select  "Company size",       :from => "Company size"
        check   "user_terms_and_conditions"
        click_button "Sign Up"

        current_url.should =~ %r(^http://[^/]+/sites/new$)
      end
    end

    describe "with the email of an archived user" do
      scenario "archived user" do
        archived_user = Factory(:user)
        archived_user.current_password = '123456'
        archived_user.archive

        fill_in "Email",              :with => archived_user.email
        fill_in "Password",           :with => "123456"
        fill_in "First name",         :with => "Rémy"
        fill_in "Last name",          :with => "Coutable"
        select "Switzerland",         :from => "Country"
        fill_in "Zip or Postal Code", :with => "CH-1024"
        check "user_terms_and_conditions"
        click_button "Sign Up"

        new_user = User.last
        new_user.should_not == archived_user
        new_user.full_name.should == "Rémy Coutable"
        new_user.email.should == archived_user.email

        current_url.should =~ %r(^http://[^/]+/sites/new$)
        page.should have_content "Rémy Coutable"
      end
    end

  end

  scenario "update email (with current password confirmation)" do
    sign_in_as :user, { :email => "old@jilion.com" }
    click_link('John Doe')
    fill_in "Email",            :with => "New@jilion.com"
    click_button "user_credentials_submit"

    fill_in "Current password", :with => "123456"
    click_button "Done"

    User.last.email.should == "new@jilion.com"
  end

  scenario "update password (with current password confirmation)" do
    sign_in_as :user
    click_link('John Doe')
    fill_in "Password", :with => "newpassword"
    click_button "user_credentials_submit"

    fill_in "Current password", :with => "123456"
    click_button "Done"

    User.last.valid_password?("newpassword").should be_true
  end

  scenario "update first name" do
    sign_in_as :user
    click_link('John Doe')
    fill_in "First name",  :with => "Bob"
    click_button "user_submit"

    page.should have_content('Bob Doe')
    User.last.full_name.should == "Bob Doe"
  end

  scenario "update first name with errors" do
    sign_in_as :user
    click_link('John Doe')
    fill_in "First name",  :with => ""
    click_button "user_submit"

    page.should have_css('.inline_errors')
    page.should have_content("First name can't be blank")
    User.last.full_name.should == "John Doe"
  end

  describe "API token" do
    scenario "create an API token", :focus => true do
      sign_in_as :user
      @current_user.api_token.should be_nil
      click_link('John Doe')
      click_button "user_api_tokens_submit"

      current_url.should =~ %r(^http://[^/]+/account/edit$)
      @current_user.api_token.should be_present
      @current_user.api_token.authentication_token.should be_present
    end

    scenario "reset an API token", :focus => true do
      sign_in_as :user
      @current_user.api_token.should be_nil
      click_link('John Doe')
      click_button "user_api_tokens_submit"

      first_api_token = @current_user.api_token.should be_present
      first_auth_token = @current_user.api_token.authentication_token.should be_present
      click_button "user_api_tokens_submit"

      current_url.should =~ %r(^http://[^/]+/account/edit$)
      @current_user.api_token.should == first_api_token
      @current_user.api_token.authentication_token.should be_present
      @current_user.api_token.authentication_token.should_not == first_auth_token
    end
  end

  scenario "delete his account (with current password confirmation)" do
    sign_in_as :user
    click_link('John Doe')

    click_button "Delete account"

    fill_in "Password", :with => "123456"
    click_button "Done"

    current_url.should =~ %r(^http://[^/]+/login$)
    page.should_not have_content "John Doe"
    User.last.should be_archived
    page.should have_content 'Bye! Your account was successfully cancelled. We hope to see you again soon.'
  end

  scenario "accept invitation should always redirect to /signup" do
    VCR.use_cassette("twitter/signup") { visit "/invitation/accept" }
    current_url.should =~ %r(^http://[^/]+/signup\?beta=over$)
  end

  context "with an authenticated user" do
    background do
      sign_in_as :user
    end

    scenario "accept invitation should redirect to /sites/new" do
      visit "/invitation/accept"
      current_url.should =~ %r(^http://[^/]+/sites/new$)
    end
  end
end

feature "session" do
  scenario "before login or signup" do
    visit "/"

    page.should_not have_content('Feedback')
    page.should_not have_content('Logout')

    page.should have_content('Login')
    page.should have_content('Documentation')
  end

  describe "login" do
    background do
      create_user :user => {
        :first_name => "John",
        :last_name => "Doe",
        :email => "john@doe.com",
        :password => "123456"
      }
    end

    scenario "not suspended user" do
      visit "/login"
      page.should_not have_content('John Doe')
      fill_in "Email",     :with => "John@doe.com"
      fill_in "Password",  :with => "123456"

      click_button "Login"

      current_url.should =~ %r(^http://[^/]+/sites/new$)
      page.should have_content "John Doe"
    end

    scenario "suspended user" do
      @current_user.suspend
      visit "/login"
      page.should_not have_content('John Doe')
      fill_in "Email",     :with => "John@doe.com"
      fill_in "Password",  :with => "123456"
      click_button "Login"

      current_url.should =~ %r(http://[^/]+/suspended)
      page.should have_content "John Doe"
    end

    scenario "archived user" do
      @current_user.current_password = '123456'
      @current_user.archive
      visit "/login"
      page.should_not have_content('John Doe')
      fill_in "Email",     :with => "John@doe.com"
      fill_in "Password",  :with => "123456"
      click_button "Login"

      current_url.should =~ %r(http://[^/]+/login)
      page.should_not have_content "John Doe"
    end
  end

  scenario "logout" do
    sign_in_as :user, { :first_name => "John", :last_name => "Doe" }
    page.should have_content "John Doe"
    click_link "Logout"

    current_url.should =~ %r(^http://[^/]+/login$)
    page.should_not have_content "John Doe"
  end
end

feature "confirmation" do
  scenario "confirmation" do
    user = create_user :user => { :first_name => "John", :last_name => "Doe", :email => "john@doe.com", :password => "123456" }, :confirm => false

    visit "/confirmation?confirmation_token=#{user.confirmation_token}"

    current_url.should =~ %r(^http://[^/]+/sites/new$)
    page.should have_content "John Doe"
  end
end
