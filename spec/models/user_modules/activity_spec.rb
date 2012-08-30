require "spec_helper"

describe UserModules::Activity do

  describe ".send_inactive_account_email" do
    context "user not created 1 week ago" do
      before do
        @user1 = create(:user, created_at: 8.days.ago)
        @user2 = create(:user, created_at: 6.days.ago)
      end

      it "doesn't send email" do
        expect { User.send_inactive_account_email }.to_not change(Delayed::Job.where { handler =~ '%Class%inactive_account%' }, :count)
      end
    end

    context "user created 1 week ago" do
      before do
        @user1 = create(:user, created_at: 7.days.ago)
        create(:site_day_stat, t: create(:site, user: @user1).token, d: Time.now, pv: { m: 2 })

        @user2 = create(:user, created_at: 7.days.ago)
        create(:site, user: @user2)

        @user1.unmemoize_all
        @user2.unmemoize_all
      end

      it "sends email to users without page visits" do
        @user1.page_visits.should eq 2
        @user2.page_visits.should eq 0
        expect { User.send_inactive_account_email }.to change(Delayed::Job.where { handler =~ '%Class%inactive_account%' }, :count).by(1)

        $worker.work_off

        last_delivery.to.should eq [@user2.email]
      end
    end
  end

end
