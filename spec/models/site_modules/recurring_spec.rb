require 'spec_helper'

describe SiteModules::Recurring do

  describe ".delay_update_last_30_days_counters_for_not_archived_sites" do
    it "delays update_last_30_days_counters_for_not_archived_sites if not already delayed" do
      expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.to \
      change(Delayed::Job.where { handler =~ '%Site%update_last_30_days_counters_for_not_archived_sites%' }, :count).by(1)
    end

    it "doesn't delay update_last_30_days_counters_for_not_archived_sites if already delayed" do
      Site.delay_update_last_30_days_counters_for_not_archived_sites
      expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.not_to \
      change(Delayed::Job.where { handler =~ '%Site%update_last_30_days_counters_for_not_archived_sites%' }, :count)
    end
  end

  describe ".update_last_30_days_counters_for_not_archived_sites" do
    it "delays itself" do
      Site.should_receive(:delay_update_last_30_days_counters_for_not_archived_sites)
      Site.update_last_30_days_counters_for_not_archived_sites
    end

    it "calls update_last_30_days_counters on each non-archived sites" do
      @active_site = Factory.create(:site, state: 'active')
      Factory.create(:site_stat, t: @active_site.token, d: Time.utc(2011,1,15).midnight, vv: { m: 6 })
      @archived_site = Factory.create(:site, state: 'archived')
      Factory.create(:site_stat, t: @archived_site.token, d: Time.utc(2011,1,15).midnight, vv: { m: 6 })

      Timecop.travel(Time.utc(2011,1,31, 12)) do
        Site.update_last_30_days_counters_for_not_archived_sites
        @active_site.reload.last_30_days_main_video_views.should == 6
        @archived_site.reload.last_30_days_main_video_views.should == 0
      end
    end
  end

  describe ".delay_send_trial_will_expire" do
    it "delays send_trial_will_expire if not already delayed" do
      expect { Site.delay_send_trial_will_expire }.to \
      change(Delayed::Job.where { handler =~ '%Site%send_trial_will_expire%' }, :count).by(1)
    end

    it "doesn't delay send_trial_will_expire if already delayed" do
      Site.delay_send_trial_will_expire
      expect { Site.delay_send_trial_will_expire }.not_to \
      change(Delayed::Job.where { handler =~ '%Site%send_trial_will_expire%' }, :count)
    end
  end

  describe ".send_trial_will_expire" do
    before(:all) do
      Site.delete_all
      @user_without_cc    = Factory.create(:user_no_cc)
      @user_with_cc       = Factory.create(:user)
      @sites_not_in_trial = [Factory.create(:site, trial_started_at: BusinessModel.days_for_trial.days.ago)]
      @sites_in_trial     = []

      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        @sites_not_in_trial << Factory.create(:site, user: @user_without_cc, state: 'archived', trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
        @sites_not_in_trial << Factory.create(:site, user: @user_without_cc, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago, first_paid_plan_started_at: 2.months.ago)
        @sites_not_in_trial << Factory.create(:site, user: @user_with_cc, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
        @sites_in_trial << Factory.create(:site, user: @user_without_cc, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
      end
    end

    it "delays itself" do
      Site.should_receive(:send_trial_will_expire)
      Site.send_trial_will_expire
    end

    it "sends 'trial will end' email" do
      ActionMailer::Base.deliveries.clear
      expect { Site.send_trial_will_expire }.to change(ActionMailer::Base.deliveries, :size).by(@sites_in_trial.size)
    end

    context "when we move 2 days in the future" do
      it "doesn't send 'trial will end' email" do
        ActionMailer::Base.deliveries.clear
        Timecop.travel(2.days.from_now) { expect { Site.send_trial_will_expire }.to_not change(ActionMailer::Base.deliveries, :size) }
      end
    end
  end

end
