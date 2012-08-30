# coding: utf-8
require 'spec_helper'

feature 'Feedback' do
  scenario 'shows a feedback form' do
    sign_in_as :user
    go 'my', 'feedback'

    current_url.should eq 'http://my.sublimevideo.dev/feedback'

    select  'Price',                 from: 'feedback_reason'
    fill_in 'user_current_password', with: '123456'
    expect { click_button 'Submit my feedback' }.to change(Feedback, :count).by(1)

    current_url.should eq 'http://my.sublimevideo.dev/sites/new'

    @current_user.reload.should_not be_archived
    feedback = Feedback.last
    feedback.reason.should eq 'price'
    feedback.user.should eq @current_user
  end

  scenario 'shows a feedback form but shows an error without a valid reason' do
    sign_in_as :user
    go 'my', 'feedback'

    current_url.should eq 'http://my.sublimevideo.dev/feedback'

    fill_in 'user_current_password', with: '123456'
    click_button 'Submit my feedback'

    current_url.should eq 'http://my.sublimevideo.dev/feedback'
    page.should have_content 'Reason must be given'
  end
end
