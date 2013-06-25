# encoding: utf-8
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

feature 'Email update' do
  context 'password without special HTML characters' do
    scenario 'do not ask for password confirmation' do
      sign_in_as :user, { email: "old@jilion.com" }
      Sidekiq::Worker.clear_all
      Timecop.travel(Time.now + 1.minute) do # for after_confirmation_path_for
        click_link('John Doe')

        within '#edit_email' do
          fill_in 'user[email]', with: "New@jilion.com"
          click_button 'Update'
        end

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

  context 'password with special HTML characters' do
    scenario 'do not ask for current password confirmation' do
      sign_in_as :user, { email: "old@jilion.com", password: "abc'def" }
      Sidekiq::Worker.clear_all
      click_link('John Doe')

      within '#edit_email' do
        fill_in 'user[email]', with: "New@jilion.com"
        click_button 'Update'
      end

      User.last.email.should eq "old@jilion.com"
      User.last.unconfirmed_email.should eq "new@jilion.com"

      page.should have_content 'You updated your account successfully, but we need to verify your new email address.'

      Sidekiq::Worker.drain_all

      last_delivery = ActionMailer::Base.deliveries.last
      last_delivery.to.should eq ["new@jilion.com"]
      last_delivery.subject.should eq "Confirm your email address"
    end
  end
end

feature 'Password update' do
  scenario 'ask for password confirmation' do
    sign_in_as :user
    click_link 'John Doe'

    within '#edit_password' do
      fill_in "Current password", with: "123456"
      fill_in "New password", with: "newpassword"
      click_button 'Update'
    end

    User.last.valid_password?("newpassword").should be_true
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
