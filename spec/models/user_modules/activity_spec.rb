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
          expect { User.send_inactive_account_email }.to_not change(Delayed::Job.where{ handler =~ '%Class%inactive_account%' }, :count)
        end
      end

      context "user created 1 week ago" do
        before do
          @user1 = create(:user, created_at: 7.days.ago)
          puts Stat::Site::Day.all_time_page_visits(@user1.sites.not_archived.map(&:token))
          site = create(:site, user: @user1)
          create(:site_day_stat, t: site.token, d: 1.day.ago.midnight, pv: { m: 2 })
          puts Stat::Site::Day.all_time_page_visits(@user1.sites.not_archived.map(&:token))

          @user2 = create(:user, created_at: 7.days.ago)
          puts Stat::Site::Day.all_time_page_visits(@user2.sites.not_archived.map(&:token))

          # Hard reload
          @user1 = User.find(@user1)
          @user2 = User.find(@user2)
        end

        it "sends email to users without page visits" do
          puts Stat::Site::Day.all_time_page_visits(@user1.sites.not_archived.map(&:token))
          puts Stat::Site::Day.all_time_page_visits(@user2.sites.not_archived.map(&:token))

          puts @user1.instance_variable_get(:@page_visits)
          puts @user2.instance_variable_get(:@page_visits)

          puts @user1.page_visits
          puts @user2.page_visits

          puts @user1.instance_variable_get(:@page_visits)
          puts @user2.instance_variable_get(:@page_visits)

          User.count.should eq 2
          @user1.page_visits.should eq 2
          @user2.page_visits.should eq 0
          expect { User.send_inactive_account_email }.to change(Delayed::Job.where{ handler =~ '%Class%inactive_account%' }, :count).by(1)

          $worker.work_off

          last_delivery.to.should eq [@user2.email]
        end
      end
    end

  end

end
