require 'spec_helper'

describe NewInactiveUserNotifier do

  describe ".send_emails" do
    context "with users not created exactly 1 week ago" do
      before {
        create(:user, created_at: 8.days.ago)
        create(:user, created_at: 6.days.ago)
      }

      it "doesn't send emails" do
        UserMailer.should_not delay(:inactive_account)
        NewInactiveUserNotifier.send_emails
      end
    end

    context "with users created 1 week ago" do
      before {
        @user1 = create(:user, created_at: 7.days.ago)
        site   = create(:site, user: @user1)
        create(:site_day_stat, t: site.token, d: 1.day.ago.midnight, pv: { m: 2 })
        @user2 = create(:user, created_at: 7.days.ago)
        Sidekiq::Worker.clear_all
      }

      it "sends email to users without page visits" do
        NewInactiveUserNotifier.send_emails
        Sidekiq::Worker.drain_all
        last_delivery.to.should eq [@user2.email]
      end
    end
  end
end
