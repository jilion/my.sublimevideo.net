require 'spec_helper'

feature 'Password recovery' do
  context 'active user' do
    let(:user) { create(:user, name: "John Doe", email: "john@doe.com", password: "123456") }

    scenario "is sent a reset password email" do
      expect(user).to be_active
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      expect(current_url).to eq "http://my.sublimevideo.dev/password/new"

      fill_in 'user[email]', with: user.email.upcase

      click_button "Send"
      expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(current_url).to eq "http://my.sublimevideo.dev/login"
    end
  end

  context 'suspended user' do
    let(:user) { create(:user, name: "John Doe", email: "john@doe.com", password: "123456", state: 'suspended') }

    scenario "is sent the reset password email" do
      expect(user).to be_suspended
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      expect(current_url).to eq "http://my.sublimevideo.dev/password/new"

      fill_in 'user[email]', with: user.email
      click_button "Send"
      expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(current_url).to eq "http://my.sublimevideo.dev/login"
    end
  end

  context 'archived user' do
    let(:archived_user) { create(:user, name: "John Doe", email: "john@doe.com", password: "123456", state: 'archived') }

    scenario "isn't sent the reset password email" do
      expect(archived_user).to be_archived
      Sidekiq::Worker.clear_all

      go 'my', "/password/new"

      expect(current_url).to eq "http://my.sublimevideo.dev/password/new"

      fill_in 'user[email]', with: archived_user.email
      click_button "Send"

      expect { Sidekiq::Worker.drain_all }.to_not change(ActionMailer::Base.deliveries, :count)

      expect(current_url).to eq "http://my.sublimevideo.dev/password"
    end

    scenario "active user is sent the reset password email" do
      expect(archived_user).to be_archived
      user = create(:user, email: archived_user.email, password: '123456')
      Sidekiq::Worker.clear_all

      go 'my', 'password/new'

      fill_in 'user[email]', with: user.email
      click_button "Send"

      expect(user.reload.reset_password_token).to be_present

      Sidekiq::Worker.drain_all

      last_delivery = ActionMailer::Base.deliveries.last
      expect(last_delivery.to).to eq [user.email]
      expect(last_delivery.subject).to eq "Password reset instructions"

      go 'my', "password/edit?reset_password_token=#{user.reset_password_token}"

      fill_in "Password", with: 'newpassword'
      click_button "Change"

      expect(user.reload.valid_password?("newpassword")).to be_truthy
    end
  end
end
