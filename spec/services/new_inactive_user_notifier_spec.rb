require 'spec_helper'

describe NewInactiveUserNotifier do

  describe ".send_emails" do
    context "with users not created exactly 1 week ago" do
      before {
        create(:user, created_at: 8.days.ago)
        create(:user, created_at: 6.days.ago)
      }

      it "doesn't send emails" do
        expect(UserMailer).not_to delay(:inactive_account)
        NewInactiveUserNotifier.send_emails
      end
    end

    context "with users created 1 week ago" do
      before {
        @user1 = create(:user, created_at: 7.days.ago)
        site   = create(:site, user: @user1, last_30_days_admin_starts: 1)
        @user2 = create(:user, created_at: 7.days.ago)
        Sidekiq::Worker.clear_all
      }

      it "sends email to users without page visits" do
        NewInactiveUserNotifier.send_emails
        Sidekiq::Worker.drain_all
        expect(last_delivery.to).to eq [@user2.email]
      end
    end
  end
end
