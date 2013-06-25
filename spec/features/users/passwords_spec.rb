require 'spec_helper'

feature 'Password recovery' do
  context 'active user' do
    let(:user) { create(:user, name: "John Doe", email: "john@doe.com", password: "123456") }

    scenario "is sent a reset password email" do
      user.should be_active
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in 'user[email]', with: user.email.upcase

      click_button "Send"
      expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :count).by(1)

      current_url.should eq "http://my.sublimevideo.dev/login"
    end
  end

  context 'suspended user' do
    let(:user) { create(:user, name: "John Doe", email: "john@doe.com", password: "123456", state: 'suspended') }

    scenario "is sent the reset password email" do
      user.should be_suspended
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in 'user[email]', with: user.email
      click_button "Send"
      expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :count).by(1)

      current_url.should eq "http://my.sublimevideo.dev/login"
    end
  end

  context 'archived user' do
    let(:archived_user) { create(:user, name: "John Doe", email: "john@doe.com", password: "123456", state: 'archived') }

    scenario "isn't sent the reset password email" do
      archived_user.should be_archived
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      current_url.should eq "http://my.sublimevideo.dev/password/new"

      fill_in 'user[email]', with: archived_user.email
      click_button "Send"

      expect { Sidekiq::Worker.drain_all }.to_not change(ActionMailer::Base.deliveries, :count)

      current_url.should eq "http://my.sublimevideo.dev/password"
    end

    scenario "active user is sent the reset password email" do
      archived_user.should be_archived
      user = create(:user, email: archived_user.email, password: '123456')
      Sidekiq::Worker.clear_all

      go 'my', 'password/new'

      fill_in 'user[email]', with: user.email
      click_button "Send"

      user.reload.reset_password_token.should be_present

      Sidekiq::Worker.drain_all

      last_delivery = ActionMailer::Base.deliveries.last
      last_delivery.to.should eq [user.email]
      last_delivery.subject.should eq "Password reset instructions"

      go 'my', "password/edit?reset_password_token=#{user.reset_password_token}"

      fill_in "Password", with: 'newpassword'
      click_button "Change"

      user.reload.valid_password?("newpassword").should be_true
    end
  end
end
