# coding: utf-8
require 'spec_helper'

feature 'Account deletion' do
  scenario 'shows a feedback form before deleting the account and succeeds with a reason and a valid current password' do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    current_url.should eq 'http://my.sublimevideo.dev/account/cancel'

    select  'Price',                 from: 'feedback_reason'
    fill_in 'user_current_password', with: '123456'
    -> { click_button 'Cancel my account' }.should delay('%Class%account_archived%', '%Class%unsubscribe%')

    current_url.should eq 'http://sublimevideo.dev/'
    get_me_the_cookies.map { |c| c['name'] }.should_not include('l')

    go 'my', 'sites'
    current_url.should eq 'http://my.sublimevideo.dev/login'

    @current_user.reload.should be_archived
    feedback = Feedback.last
    feedback.reason.should eq 'price'
    feedback.user.should eq @current_user
  end

  scenario 'shows a feedback form before deleting the account but shows an error without a valid reason' do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    current_url.should eq 'http://my.sublimevideo.dev/account/cancel'

    fill_in 'user_current_password', with: '123456'
    click_button 'Cancel my account'

    current_url.should eq 'http://my.sublimevideo.dev/account/cancel'
    page.should have_content 'Reason must be given'
  end

  scenario 'shows a feedback form before deleting the account but shows an error without a valid current password' do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    current_url.should eq 'http://my.sublimevideo.dev/account/cancel'

    select  'Price',                 from: 'feedback_reason'
    fill_in 'user_current_password', with: '654321'
    click_button 'Cancel my account'

    current_url.should eq 'http://my.sublimevideo.dev/account/cancel'
    page.should have_content 'Please enter your current password to confirm the cancellation'
  end
end
