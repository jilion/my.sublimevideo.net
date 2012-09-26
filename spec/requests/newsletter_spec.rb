# coding: utf-8
require 'spec_helper'

feature "Newsletter subscription" do
  let(:user) { create(:user) }

  context 'user is not logged-in' do
    pending 'subscribed to the newsletter after log-in' do
      go 'my', '/newsletter/subscribe'

      current_url.should eq 'http://my.sublimevideo.dev/login'

      fill_in 'Email',    with: user.email
      fill_in 'Password', with: '123456'

      -> { click_button 'Log In' }.should delay('%NewsletterManager%subscribe%')

      current_url.should eq 'http://my.sublimevideo.dev/sites/new'

      page.should have_content I18n.t('flash.newsletter.subscribe')
      page.should have_selector 'form.new_support_request'
    end
  end

  context 'user is logged-in' do
    background do
      sign_in_as :user
      create(:site, user: @current_user)
    end

    scenario 'subscribed to the newsletter after log-in' do
      -> { go 'my', '/newsletter/subscribe' }.should delay('%CampaignMonitorWrapper%subscribe%')

      current_url.should eq 'http://my.sublimevideo.dev/sites'

      page.should have_content I18n.t('flash.newsletter.subscribe')
    end
  end

end
