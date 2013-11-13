# coding: utf-8
require 'spec_helper'

feature 'Feedback' do
  scenario 'shows a feedback form' do
    sign_in_as :user
    go 'my', 'feedback'

    expect(current_url).to eq 'http://my.sublimevideo.dev/feedback'

    select  'Price',                 from: 'feedback_reason'
    fill_in 'user_current_password', with: '123456'
    expect { click_button 'Submit my feedback' }.to change(Feedback, :count).by(1)

    expect(current_url).to eq 'http://my.sublimevideo.dev/assistant/new-site'

    expect(@current_user.reload).not_to be_archived
    feedback = Feedback.last
    expect(feedback.reason).to eq 'price'
    expect(feedback.user).to eq @current_user
  end

  scenario 'shows a feedback form but shows an error without a valid reason' do
    sign_in_as :user
    go 'my', 'feedback'

    expect(current_url).to eq 'http://my.sublimevideo.dev/feedback'

    fill_in 'user_current_password', with: '123456'
    click_button 'Submit my feedback'

    expect(current_url).to eq 'http://my.sublimevideo.dev/feedback'
    expect(page).to have_content 'Reason must be given'
  end
end
