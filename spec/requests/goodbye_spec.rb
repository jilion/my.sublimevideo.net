# coding: utf-8
require 'spec_helper'

feature 'Account deletion', :focus do
  scenario 'shows a feedback form before deleting the account and succeeds with a reason and a valid current password' do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    current_url.should eq 'http://my.sublimevideo.dev/goodbye'

    select  'Price',                 from: 'goodbye_feedback_reason'
    fill_in 'user_current_password', with: '123456'
    click_button 'Cancel my account'

    current_url.should eq 'http://my.sublimevideo.dev/login'
    get_me_the_cookies.map { |c| c['name'] }.should_not include('l')

    go 'my', 'sites'
    current_url.should eq 'http://my.sublimevideo.dev/login'

    @current_user.reload.should be_archived
    goodbye_feedback = GoodbyeFeedback.last
    goodbye_feedback.reason.should eq 'price'
    goodbye_feedback.user.should eq @current_user

    last_delivery = ActionMailer::Base.deliveries.last
    last_delivery.to.should eq [@current_user.email]
    last_delivery.subject.should eq 'Your account has been deleted'
    last_delivery.body.encoded.should include 'Your account has been deleted.'
  end

  scenario 'shows a feedback form before deleting the account but shows an error without a valid reason' do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    current_url.should eq 'http://my.sublimevideo.dev/goodbye'

    fill_in 'user_current_password', with: '123456'
    click_button 'Cancel my account'

    current_url.should eq 'http://my.sublimevideo.dev/goodbye'
    page.should have_content 'Reason must be given'
  end

  scenario 'shows a feedback form before deleting the account but shows an error without a valid current password' do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    current_url.should eq 'http://my.sublimevideo.dev/goodbye'

    select  'Price',                 from: 'goodbye_feedback_reason'
    fill_in 'user_current_password', with: '654321'
    click_button 'Cancel my account'

    current_url.should eq 'http://my.sublimevideo.dev/goodbye'
    page.should have_content 'Please enter your current passowrd to confirm the cancellation'
  end
end
