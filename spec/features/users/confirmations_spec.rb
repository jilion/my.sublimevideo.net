require 'spec_helper'

feature 'Confirmation' do
  scenario "confirmation" do
    user = create(:user, name: "John Doe", email: "john@doe.com", password: "123456")

    go 'my', 'login'
    click_link "Didn't receive confirmation instructions?"

    fill_in 'user[email]',    with: user.email
    Sidekiq::Worker.clear_all
    click_button 'Resend'

    Sidekiq::Worker.drain_all
    path = %r{href=\"https://my.sublimevideo.dev/(confirmation\?confirmation_token=\S+)\"}.match(ActionMailer::Base.deliveries.last.body.encoded)[1]

    go 'my', path
    current_url.should eq "http://my.sublimevideo.dev/login"

    fill_and_submit_login(user, password: '123456')
    current_url.should eq 'http://my.sublimevideo.dev/account/more-info'

    fill_in "Name",               with: "John Doe"
    fill_in "Zip or Postal Code", with: "2001"
    select  "France",             from: "Country"
    fill_in "Company name",       with: "Unknown SA"
    select  "6-20 employees",     from: "Company size"
    check "user_use_company"
    fill_in "user_confirmation_comment", with: "I love this player!"
    click_button "Continue"

    page.should have_content I18n.t('devise.users.updated')

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    get_me_the_cookie("l")[:value].should eq '1'
    page.should have_content "John Doe"
  end
end
