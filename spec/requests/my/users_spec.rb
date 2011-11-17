# coding: utf-8
require 'spec_helper'

feature "Users" do

  describe "sign-up redirections" do
    scenario "redirect /register to /signup" do
      VCR.use_cassette("twitter/signup") { go 'my', '/register' }
      current_url.should =~ %r(^http://[^/]+/$)
    end

    scenario "redirect /sign_up to /signup" do
      VCR.use_cassette("twitter/signup") { go 'my', '/sign_up' }
      current_url.should =~ %r(^http://[^/]+/$)
    end
  end

  describe "log-in redirections" do
    scenario "redirect /log_in to /login" do
      go 'my', '/log_in'
      current_url.should =~ %r(^http://[^/]+/$)
    end

    scenario "redirect /sign_in to /login" do
      go 'my', '/sign_in'
      current_url.should =~ %r(^http://[^/]+/$)
    end

    scenario "redirect /signin to /login" do
      go 'my', '/signin'
      current_url.should =~ %r(^http://[^/]+/$)
    end
  end

  context "logged-in user" do
    background do
      sign_in_as :user
    end

    describe "log-out redirections" do
      scenario "redirect /log_out to /logout" do
        page.should have_content @current_user.name
        go 'my', '/log_out'
        page.should have_no_content @current_user.name
      end

      scenario "redirect /sign_out to /logout" do
        page.should have_content @current_user.name
        go 'my', '/sign_out'
        page.should have_no_content @current_user.name
      end

      scenario "redirect /signout to /logout" do
        page.should have_content @current_user.name
        go 'my', '/signout'
        page.should have_no_content @current_user.name
      end
    end
  end

  describe "signup" do
    before(:each) do
      VCR.use_cassette("twitter/signup") { go 'my', '/?p=signup' }
      current_url.should =~ %r(^http://[^/]+/?p=signup$)
    end

    describe "with the email of an archived user" do
      scenario "archived user" do
        archived_user = Factory.create(:user)
        archived_user.current_password = '123456'
        archived_user.archive

        fill_in "Name",     with: "Rémy Coutable"
        fill_in "Email",    with: archived_user.email
        fill_in "Password", with: "123456"
        check "user_terms_and_conditions"
        click_button "Sign Up"

        new_user = User.last
        new_user.should_not eq archived_user
        new_user.name.should eq "Rémy Coutable"
        new_user.email.should eq archived_user.email

        current_url.should =~ %r(^http://my.[^/]+/sites/new$)
        page.should have_content "Rémy Coutable"
      end
    end

  end

  scenario "current password confirmation accept password with HTML special characters" do
    sign_in_as :user, { email: "old@jilion.com", password: "abc'def" }
    click_link('John Doe')

    fill_in "Email", with: "New@jilion.com"
    click_button "user_credentials_submit"

    fill_in "Current password", with: "abc'def"
    click_button "Done"

    User.last.email.should eq "new@jilion.com"
  end

  scenario "update email (with current password confirmation)" do
    sign_in_as :user, { email: "old@jilion.com" }
    click_link('John Doe')

    fill_in "Email", with: "New@jilion.com"
    click_button "user_credentials_submit"

    fill_in "Current password", with: "123456"
    click_button "Done"

    User.last.email.should eq "new@jilion.com"
  end

  scenario "update password (with current password confirmation)" do
    sign_in_as :user
    click_link('John Doe')

    fill_in "Password", with: "newpassword"
    click_button "user_credentials_submit"

    fill_in "Current password", with: "123456"
    click_button "Done"

    User.last.valid_password?("newpassword").should be_true
  end

  describe "API" do
    scenario "API pages are not accessible" do
      sign_in_as :user
      click_link('John Doe')
      page.should have_no_content("API")

      visit "/account/applications"
      current_url.should =~ %r(^http://[^/]+/account$)
    end

    scenario "API pages are accessible to @jilion.com emails" do
      sign_in_as :user, email: "remy@jilion.com"
      click_link('John Doe')
      page.should have_content("API")

      visit "/account/applications"
      current_url.should =~ %r(^http://[^/]+/account/applications$)
    end
  end

  scenario "delete his account (with current password confirmation)" do
    sign_in_as :user
    click_link('John Doe')
    click_button "Delete account"

    fill_in "Password", with: "123456"
    click_button "Done"

    current_url.should =~ %r(^http://[^/]+/login$)
    page.should_not have_content "John Doe"
    @current_user.reload.should be_archived
    page.should have_content 'Bye! Your account was successfully cancelled. We hope to see you again soon.'

    last_delivery = ActionMailer::Base.deliveries.last
    last_delivery.to.should eql [@current_user.email]
    last_delivery.subject.should eql "Your account has been deleted"
    last_delivery.body.encoded.should include "Your account has been deleted."
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
    go "/"

    page.should_not have_content('Feedback')
    page.should_not have_content('Logout')

    page.should have_content('Login')
    page.should have_content('Documentation')
  end

  describe "login" do
    background do
      create_user user: {
        name: "John Doe",
        email: "john@doe.com",
        password: "123456"
      }
    end

    scenario "not suspended user" do
      visit "/login"
      page.should_not have_content('John Doe')
      fill_in "Email",    with: "John@doe.com"
      fill_in "Password", with: "123456"

      click_button "Login"

      current_url.should =~ %r(^http://[^/]+/sites/new$)
      page.should have_content "John Doe"
    end

    scenario "suspended user" do
      @current_user.suspend
      visit "/login"
      page.should_not have_content('John Doe')
      fill_in "Email",    with: "John@doe.com"
      fill_in "Password", with: "123456"
      click_button "Login"

      current_url.should =~ %r(http://[^/]+/suspended)
      page.should have_content "John Doe"
    end

    scenario "archived user" do
      @current_user.current_password = '123456'
      @current_user.archive
      visit "/login"
      page.should_not have_content('John Doe')
      fill_in "Email",    with: "John@doe.com"
      fill_in "Password", with: "123456"
      click_button "Login"

      current_url.should =~ %r(http://[^/]+/login)
      page.should_not have_content "John Doe"
    end
  end

  scenario "logout" do
    sign_in_as :user, { name: "John Doe" }
    page.should have_content "John Doe"
    click_link "Logout"

    current_url.should =~ %r(^http://[^/]+/login$)
    page.should_not have_content "John Doe"
  end
end

feature "confirmation" do
  scenario "confirmation" do
    user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456" }, confirm: false

    visit "/confirmation?confirmation_token=#{user.confirmation_token}"

    current_url.should =~ %r(^http://[^/]+/sites/new$)
    page.should have_content "John Doe"
  end
end
