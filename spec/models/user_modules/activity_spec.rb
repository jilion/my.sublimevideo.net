require 'spec_helper'

describe UserModules::Activity do

  describe 'Class Methods' do

    describe ".send_inactive_account_email" do
      context "user not created 1 week ago" do
        before do
          @user1 = create(:user, created_at: 8.days.ago)
          @user2 = create(:user, created_at: 6.days.ago)
        end

        it "doesn't send email" do
          UserMailer.should_not delay(:inactive_account)
          User.send_inactive_account_email
        end
      end

      context "user created 1 week ago" do
        before do
          @user1 = create(:user, created_at: 7.days.ago)
          site = create(:site, user: @user1)
          create(:site_day_stat, t: site.token, d: 1.day.ago.midnight, pv: { m: 2 })

          @user2 = create(:user, created_at: 7.days.ago)

          # Hard reload
          @user1 = User.find(@user1)
          @user2 = User.find(@user2)
        end

        it "sends email to users without page visits" do
          User.count.should eq 2
          @user1.page_visits.should eq 2
          @user2.page_visits.should eq 0

          User.send_inactive_account_email

          Sidekiq::Worker.drain_all
          last_delivery.to.should eq [@user2.email]
        end
      end
    end

  end

end
