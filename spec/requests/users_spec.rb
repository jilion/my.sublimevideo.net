# coding: utf-8
require 'spec_helper'

feature 'Redirections' do
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
end

feature 'Account page access' do

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

feature 'Sign Up' do
  background do
    go 'my', '/signup'
    current_url.should eq "http://my.sublimevideo.dev/signup"
  end

  scenario 'display errors if any' do
    fill_in "Email",    with: 'user@example.org'
    fill_in "Password", with: "123456"
    click_button "Sign Up"

    current_url.should eq "http://my.sublimevideo.dev/signup"
    page.should have_content 'Terms & Conditions must be accepted'

    fill_in "Password", with: "123456"
    check "user_terms_and_conditions"
    click_button "Sign Up"

    user = User.last
    user.name.should be_nil
    user.email.should eq 'user@example.org'

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    get_me_the_cookie("l")[:value].should eq '1'
    page.should have_content I18n.t("devise.users.signed_up")
    page.should have_content user.email
  end

  scenario 'accepts new sign up with the email of an archived user' do
    archived_user = create(:user)
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

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    get_me_the_cookie("l")[:value].should eq '1'
    page.should have_content I18n.t("devise.users.signed_up")
    page.should have_content archived_user.email
  end
end

feature 'Current password confirmation' do
  scenario "accept password with HTML special characters" do
    sign_in_as :user, { email: "old@jilion.com", password: "abc'def" }
    click_link('John Doe')

    fill_in "Email", with: "New@jilion.com"
    click_button "user_credentials_submit"

    fill_in "Current password", with: "abc'def"
    click_button "Done"

    User.last.email.should eq "old@jilion.com"
    User.last.unconfirmed_email.should eq "new@jilion.com"
  end
end

feature 'Email update' do
  scenario 'ask for password confirmation' do
    sign_in_as :user, { email: "old@jilion.com" }
    Sidekiq::Worker.clear_all
    Timecop.travel(Time.now + 1.minute) do # for after_confirmation_path_for
      click_link('John Doe')

      fill_in "Email", with: "New@jilion.com"
      click_button "user_credentials_submit"

      fill_in "Current password", with: "123456"
      click_button "Done"

      User.last.email.should eq "old@jilion.com"
      User.last.unconfirmed_email.should eq "new@jilion.com"

      Sidekiq::Worker.drain_all

      last_delivery = ActionMailer::Base.deliveries.last
      last_delivery.to.should eq [User.last.unconfirmed_email]
      last_delivery.subject.should eq "Confirm your email address"

      go 'my', "confirmation?confirmation_token=#{User.last.confirmation_token}"

      User.last.email.should eq "new@jilion.com"
      current_url.should eq "http://my.sublimevideo.dev/assistant/new-site" # redirected from /sites
    end
  end
end

feature 'Password update' do
  scenario 'ask for password confirmation' do
    sign_in_as :user
    click_link 'John Doe'

    fill_in "New password", with: "newpassword"
    click_button "user_credentials_submit"

    fill_in "Current password", with: "123456"
    click_button "Done"

    User.last.valid_password?("newpassword").should be_true
  end
end

feature 'Password recovery' do

  context 'active user' do
    scenario "send reset password email" do
      user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456" }
      user.should be_active
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in "Email", with: "john@doe.com"

      click_button "Send"
      expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :count).by(1)

      current_url.should eq "http://my.sublimevideo.dev/login"
    end
  end

  context 'suspended user' do
    scenario "send reset password email" do
      user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456", state: 'suspended' }
      user.should be_suspended
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in "Email", with: "john@doe.com"
      click_button "Send"
      expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :count).by(1)

      current_url.should eq "http://my.sublimevideo.dev/login"
    end
  end

  context 'archived user' do
    scenario "doesn't send reset password email" do
      user = create_user user: { name: "John Doe", email: "john@doe.com", password: "123456", state: 'archived' }
      user.should be_archived
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in "Email", with: "john@doe.com"
      click_button "Send"
      expect { Sidekiq::Worker.drain_all }.to_not change(ActionMailer::Base.deliveries, :count)

      current_url.should eq "http://my.sublimevideo.dev/password"
    end

    scenario "doesn't take in account archived user" do
      email = 'thibaud@jilion.com'
      archived_user = create(:user, email: email, password: '123456')
      archived_user.current_password = '123456'
      archived_user.archive
      user = create(:user, email: email, password: '123456')
      Sidekiq::Worker.clear_all

      go 'my', 'password/new'

      fill_in "Email", with: email
      click_button "Send"

      user.reload.reset_password_token.should be_present

      Sidekiq::Worker.drain_all

      last_delivery = ActionMailer::Base.deliveries.last
      last_delivery.to.should eq [user.email]
      last_delivery.subject.should eq "Password reset instructions"

      go 'my', "password/edit?reset_password_token=#{user.reset_password_token}"

      fill_in "Password", with: 'newpassword'
      click_button "Change"

      user.reload.valid_password?("newpassword").should be_true
    end
  end

end

feature "Credentials update" do
  background do
    sign_in_as :user
    Sidekiq::Worker.clear_all
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

    page.should have_content 'You updated your account successfully, but we need to verify your new email address.'

    Sidekiq::Worker.drain_all

    last_delivery = ActionMailer::Base.deliveries.last
    last_delivery.to.should eq ["zeno@jilion.com"]
    last_delivery.subject.should eq "Confirm your email address"
  end

  scenario "It's possible to update password" do
    email = @current_user.email
    within '#edit_credentials' do
      fill_in "New password", with: "654321"
      click_button "Update"
    end

    fill_in "Current password", with: '123456'
    click_button "Done"
    current_url.should eq "http://my.sublimevideo.dev/account"
  end
end

feature "'More info' update" do
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

feature 'Session management' do
  let(:user) { create(:user) }

  scenario "login" do
    go 'my', '/gs-login'

    fill_in "Email",    with: user.email
    fill_in "Password", with: "123456"

    click_button "Log In"

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
  end

  scenario "logout" do
    sign_in_as :user, { name: "John Doe" }
    page.should have_content "John Doe"
    click_link "logout"

    # Not working with external url
    # current_url.should eq "http://sublimevideo.dev/"
    page.should_not have_content "John Doe"
  end
end

feature 'Confirmation' do
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

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    get_me_the_cookie("l")[:value].should eq '1'
    page.should have_content "John Doe"
  end
end

feature 'API' do
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
