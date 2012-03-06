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
        get_me_the_cookies.map { |c| c['name'] }.should_not include("l")
      end

      scenario "redirect /sign_out to /logout" do
        page.should have_content @current_user.name
        go 'my', '/sign_out'
        page.should have_no_content @current_user.name
        get_me_the_cookies.map { |c| c['name'] }.should_not include("l")
      end

      scenario "redirect /signout to /logout" do
        page.should have_content @current_user.name
        go 'my', '/signout'
        page.should have_no_content @current_user.name
        get_me_the_cookies.map { |c| c['name'] }.should_not include("l")
      end
    end
  end

  describe "signup" do
    background do
      go '/?p=signup'
      current_url.should eq "http://sublimevideo.dev/?p=signup"
    end

    describe "with the email of an archived user" do
      scenario "archived user" do
        archived_user = Factory.create(:user)
        archived_user.current_password = '123456'
        archived_user.archive

        fill_in "Email",    with: archived_user.email
        fill_in "Password", with: "123456"
        check "user_terms_and_conditions"
        click_button "Sign Up"

        new_user = User.last
        new_user.should_not eq archived_user
        new_user.name.should be_nil
        new_user.email.should eq archived_user.email

        current_url.should eq "http://my.sublimevideo.dev/sites/new"
        get_me_the_cookie("l")[:value].should eq '1'
        page.should have_content I18n.t("devise.users.signed_up")
        page.should have_content archived_user.email
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

    User.last.email.should eq "old@jilion.com"
    User.last.unconfirmed_email.should eq "new@jilion.com"
  end

  scenario "update email (with current password confirmation)" do
    sign_in_as :user, { email: "old@jilion.com" }
    Timecop.travel(Time.now + 1.minute) do # for after_confirmation_path_for
      click_link('John Doe')

      fill_in "Email", with: "New@jilion.com"
      click_button "user_credentials_submit"

      fill_in "Current password", with: "123456"
      click_button "Done"

      User.last.email.should eq "old@jilion.com"
      User.last.unconfirmed_email.should eq "new@jilion.com"

      last_delivery = ActionMailer::Base.deliveries.last
      last_delivery.to.should eq [User.last.unconfirmed_email]
      last_delivery.subject.should eq "Confirmation instructions"

      go 'my', "confirmation?confirmation_token=#{User.last.confirmation_token}"

      User.last.email.should eq "new@jilion.com"
      current_url.should eq "http://my.sublimevideo.dev/sites/new" # redirected from /sites
    end
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

  scenario "recover password (with archived user with same email)" do
    email = 'thibaud@jilion.com'
    archived_user = Factory.create(:user, email: email, password: '123456')
    archived_user.current_password = '123456'
    archived_user.archive
    user = Factory.create(:user, email: email, password: '123456')

    go 'my', 'password/new'

    fill_in "Email", with: email
    click_button "Send"

    user.reload.reset_password_token.should be_present


    last_delivery = ActionMailer::Base.deliveries.last
    last_delivery.to.should eq [user.email]
    last_delivery.subject.should eq "Reset password instructions"

    go 'my', "password/edit?reset_password_token=#{user.reset_password_token}"

    fill_in "Password", with: 'newpassword'
    click_button "Change"

    user.reload.valid_password?("newpassword").should be_true
  end

  describe "Access the account page" do

    context "When the user is not logged-in" do
      background do
        create_user(user: {})
      end

      scenario "is redirected to log in page" do
        go 'my', 'account'

        current_url.should eq "http://my.sublimevideo.dev/login"
      end
    end

    context "When the user is logged-in" do
      background do
        sign_in_as :user
      end

      scenario "can access the page directly" do
        go 'my', 'account'

        current_url.should eq "http://my.sublimevideo.dev/account"
      end

      scenario "can access the page via a link in the menu" do
        within '#menu' do
          click_link @current_user.name

          current_url.should eq "http://my.sublimevideo.dev/account"
        end
      end
    end

  end

  describe "Credentials update" do

    context "When the user is logged-in" do
      background do
        sign_in_as :user
        go 'my', 'account'
      end

      scenario "It's possible to update email" do
        within '#edit_credentials' do
          fill_in "Email", with: "zeno@jilion.com"

          click_button "Update"
        end

        fill_in "Current password", with: '123456'
        click_button "Done"

        User.find(@current_user.id).unconfirmed_email.should eq "zeno@jilion.com"

        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should eq ["zeno@jilion.com"]
        last_delivery.subject.should eq "Confirmation instructions"
      end

      scenario "It's possible to update password" do
        email = @current_user.email
        within '#edit_credentials' do
          fill_in "New password", with: "654321"
          click_button "Update"
        end

        fill_in "Current password", with: '123456'
        click_button "Done"
        current_url.should eq "http://my.sublimevideo.dev/login"

        fill_in 'Email',    with: email
        fill_in 'Password', with: '654321'
        click_button 'Log In'

        current_url.should eq "http://my.sublimevideo.dev/account"
      end
    end

  end

  describe "'More info' update" do

    context "When the user is logged-in" do
      background do
        sign_in_as :user, billing_address_1: ''
        go 'my', 'account'
      end

      scenario "It's possible to update postal_code and country from the edit account page" do
        within '#edit_more_info' do
          fill_in "Name",               with: "Bob Doe"
          fill_in "Zip or Postal Code", with: "91470"
          select  "France",             from: "Country"
          fill_in "Company name",       with: "Jilion"
          select  "6-20 employees",     from: "Company size"
          check "user_use_company"
          click_button "Update"
        end

        @current_user.reload.name.should eq "Bob Doe"
        @current_user.postal_code.should eq "91470"
        @current_user.country.should eq "FR"
        @current_user.company_name.should eq "Jilion"
        @current_user.company_employees.should eq "6-20 employees"
      end

      scenario "It's possible to update only certain fields" do
        within '#edit_more_info' do
          fill_in "Name",               with: "Bob Doe"
          fill_in "Zip or Postal Code", with: ""
          select  "France",             from: "Country"
          fill_in "Company name",       with: ""
          select  "6-20 employees",     from: "Company size"
          check "user_use_company"
          click_button "Update"
        end

        @current_user.reload.name.should eq "Bob Doe"
        @current_user.postal_code.should eq ""
        @current_user.country.should eq "FR"
        @current_user.company_name.should eq ""
        @current_user.company_employees.should eq "6-20 employees"
      end
    end

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

    current_url.should eq "http://sublimevideo.dev/"
    get_me_the_cookies.map { |c| c['name'] }.should_not include("l")
    page.should_not have_content "John Doe"
    @current_user.reload.should be_archived

    last_delivery = ActionMailer::Base.deliveries.last
    last_delivery.to.should eq [@current_user.email]
    last_delivery.subject.should eq "Your account has been deleted"
    last_delivery.body.encoded.should include "Your account has been deleted."
  end
end

feature "session" do
  scenario "logout" do
    sign_in_as :user, { name: "John Doe" }
    page.should have_content "John Doe"
    click_link "Logout"

    current_url.should eq "http://sublimevideo.dev/"
    page.should_not have_content "John Doe"
  end
end

feature "confirmation" do
  scenario "confirmation" do
    user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456" }, confirm: false

    go 'my', "/confirmation?confirmation_token=#{user.confirmation_token}"

    current_url.should eq "http://my.sublimevideo.dev/account/more-info"
    page.should have_content I18n.t("devise.confirmations.user.confirmed")

    fill_in "Name",               with: "John Doe"
    fill_in "Zip or Postal Code", with: "2001"
    select  "France",             from: "Country"
    fill_in "Company name",       with: "Unknown SA"
    select  "6-20 employees",     from: "Company size"
    check "user_use_company"
    fill_in "user_confirmation_comment", with: "I love this player!"
    click_button "Continue"

    current_url.should eq "http://my.sublimevideo.dev/sites/new"
    get_me_the_cookie("l")[:value].should eq '1'
    page.should have_content "John Doe"
  end
end

feature "password reset", :focus do
  context "user is active" do
    scenario "send reset password email" do
      user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456" }
      user.should be_active

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in "Email", with: "john@doe.com"
      expect { click_button "Send" }.to change(ActionMailer::Base.deliveries, :count).by(1)

      current_url.should eq "http://my.sublimevideo.dev/login"
    end
  end

  context "user is suspended" do
    scenario "send reset password email" do
      user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456", state: 'suspended' }
      user.should be_suspended

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in "Email", with: "john@doe.com"
      expect { click_button "Send" }.to change(ActionMailer::Base.deliveries, :count).by(1)

      current_url.should eq "http://my.sublimevideo.dev/login"
    end
  end

  context "user is archived" do
    scenario "doesn't send reset password email" do
      user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456", state: 'archived' }
      user.should be_archived

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in "Email", with: "john@doe.com"
      expect { click_button "Send" }.to_not change(ActionMailer::Base.deliveries, :count)

      current_url.should eq "http://my.sublimevideo.dev/password"
    end
  end
end
