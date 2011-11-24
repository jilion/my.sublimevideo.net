# coding: utf-8
require 'spec_helper'

feature "Users" do

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
    background do
      go '/?p=signup'
      current_url.should eq "http://www.sublimevideo.dev/?p=signup"
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

        current_url.should eq "http://my.sublimevideo.dev/sites/new"
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

    fill_in "New password", with: "newpassword"
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

      go 'my', "/account/applications"
      current_url.should eq "http://my.sublimevideo.dev/account"
    end

    scenario "API pages are accessible to @jilion.com emails" do
      sign_in_as :user, email: "remy@jilion.com"
      click_link('John Doe')
      # page.should have_content("API")

      go 'my', "/account/applications"
      current_url.should eq "http://my.sublimevideo.dev/account/applications"
    end
  end

  scenario "delete his account (with current password confirmation)" do
    sign_in_as :user
    click_link('John Doe')
    click_button "Delete account"

    fill_in "user_current_password", with: "123456"

    click_button "Done"
    current_url.should eq "http://www.sublimevideo.dev/"
    page.should_not have_content "John Doe"
    @current_user.reload.should be_archived

    last_delivery = ActionMailer::Base.deliveries.last
    last_delivery.to.should eq [@current_user.email]
    last_delivery.subject.should eq "Your account has been deleted"
    last_delivery.body.encoded.should include "Your account has been deleted."
  end

  scenario "accept invitation should always redirect to /signup" do
    go 'my', "/invitation/accept"
    current_url.should eq "http://www.sublimevideo.dev/?p=signup&beta=over"
  end

  context "with an authenticated user" do
    background do
      sign_in_as :user
    end

    scenario "accept invitation should redirect to /sites/new" do
      go 'my', "/invitation/accept"
      current_url.should eq "http://my.sublimevideo.dev/sites/new"
    end
  end
end

feature "session" do
  scenario "logout" do
    sign_in_as :user, { name: "John Doe" }
    page.should have_content "John Doe"
    click_link "Logout"

    current_url.should eq "http://www.sublimevideo.dev/"
    page.should_not have_content "John Doe"
  end
end

feature "confirmation" do
  scenario "confirmation" do
    user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456" }, confirm: false

    go 'my', "/confirmation?confirmation_token=#{user.confirmation_token}"

    current_url.should eq "http://my.sublimevideo.dev/sites/new"
  end
end
