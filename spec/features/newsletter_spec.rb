# encoding: utf-8
require 'spec_helper'

feature "Newsletter subscription" do
  let(:user) { create(:user) }

  context 'user is not logged-in' do
    scenario 'subscribed to the newsletter after log-in' do
      go 'my', '/newsletter/subscribe'

      current_url.should eq 'http://my.sublimevideo.dev/login'

      fill_in 'user[email]',    with: user.email
      fill_in 'user[password]', with: '123456'

      NewsletterSubscriptionManager.should delay(:subscribe).with(user.id)

      click_button 'Log In'

      current_url.should eq 'http://my.sublimevideo.dev/assistant/new-site'

      page.should have_content I18n.t('flash.newsletter.subscribe')
    end
  end

  context 'user is logged-in' do
    background do
      sign_in_as :user
      SiteManager.new(build(:site, user: @current_user)).create
    end

    scenario 'subscribed to the newsletter after log-in' do
      NewsletterSubscriptionManager.should delay(:subscribe).with(@current_user.id)

      go 'my', '/newsletter/subscribe'

      current_url.should eq 'http://my.sublimevideo.dev/sites'

      page.should have_content I18n.t('flash.newsletter.subscribe')
    end
  end

end
