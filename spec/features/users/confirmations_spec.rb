require 'spec_helper'

feature 'Confirmation' do
  scenario "confirmation" do
    user = create(:user, name: "John Doe", email: "john@doe.com", password: "123456")

    go 'my', "/confirmation?confirmation_token=#{user.confirmation_token}"

    current_url.should eq "http://my.sublimevideo.dev/account/more-info"
    page.should have_content I18n.t('devise.confirmations.user.confirmed')

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
