# coding: utf-8
require 'spec_helper'

feature 'Account deletion', :focus do
  scenario 'shows a feedback form before deleting the account' do
    sign_in_as :user
    click_link 'John Doe'
    click_link 'Cancel account'

    current_url.should eq 'http://my.sublimevideo.dev/goodbye'

    select  'Price',                 from: 'goodbye_feedback_reason'
    fill_in 'user_current_password', with: '123456'
    click_button 'Cancel my account'

    # Not working with external url
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
end
