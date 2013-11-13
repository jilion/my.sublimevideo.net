# coding: utf-8
require 'spec_helper'

feature 'Account deletion' do
  background do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    expect(current_url).to eq 'http://my.sublimevideo.dev/account/cancel'
  end

  scenario 'shows a feedback form before deleting the account and succeeds with a reason and a valid current password' do
    # FIXME: it seems that the context is reset inside the lambda...
    select  'Price',                 from: 'feedback_reason'
    fill_in 'user_current_password', with: '123456'
    # -> { page.driver.click_button 'Cancel my account' }.should delay('%Class%account_archived%', '%Class%unsubscribe%')
    click_button 'Cancel my account'

    expect(current_url).to eq 'http://sublimevideo.dev/'
    expect(get_me_the_cookies.map { |c| c['name'] }).not_to include('l')

    go 'my', 'sites'
    expect(current_url).to eq 'http://my.sublimevideo.dev/login'

    expect(@current_user.reload).to be_archived
    feedback = Feedback.last
    expect(feedback.reason).to eq 'price'
    expect(feedback.user).to eq @current_user
  end

  scenario 'shows a feedback form before deleting the account but shows an error without a valid reason' do
    fill_in 'user_current_password', with: '123456'
    click_button 'Cancel my account'

    expect(current_url).to eq 'http://my.sublimevideo.dev/account/cancel'
    expect(page).to have_content 'Reason must be given'
  end

  scenario 'shows a feedback form before deleting the account but shows an error without a valid current password' do
    select  'Price',                 from: 'feedback_reason'
    fill_in 'user_current_password', with: '654321'
    click_button 'Cancel my account'

    expect(current_url).to eq 'http://my.sublimevideo.dev/account/cancel'
    expect(page).to have_content 'Please enter your current password to confirm the cancellation'
  end
end
