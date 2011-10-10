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
      @active_site = FactoryGirl.create(:site, state: 'active')
      FactoryGirl.create(:site_usage, site_id: @active_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)
      @archived_site = FactoryGirl.create(:site, state: 'archived')
      FactoryGirl.create(:site_usage, site_id: @archived_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)

      Timecop.travel(Time.utc(2011,1,31, 12)) do
        Site.update_last_30_days_counters_for_not_archived_sites
        @active_site.reload.last_30_days_main_video_views.should == 6
        @archived_site.reload.last_30_days_main_video_views.should == 0
      end
    end
  end

  describe ".delay_send_trial_will_end" do
    it "delays send_trial_will_end if not already delayed" do
      expect { Site.delay_send_trial_will_end }.to \
      change(Delayed::Job.where { handler =~ '%Site%send_trial_will_end%' }, :count).by(1)
    end

    it "doesn't delay send_trial_will_end if already delayed" do
      Site.delay_send_trial_will_end
      expect { Site.delay_send_trial_will_end }.not_to \
      change(Delayed::Job.where { handler =~ '%Site%send_trial_will_end%' }, :count)
    end
  end

  describe ".send_trial_will_end" do
    before(:all) do
      Site.delete_all
      @site_not_in_trial = FactoryGirl.create(:site, trial_started_at: BusinessModel.days_for_trial.days.ago)
      @sites_in_trial = []

      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        @sites_in_trial << FactoryGirl.create(:site, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
      end
    end

    it "delays itself" do
      Site.should_receive(:send_trial_will_end)
      Site.send_trial_will_end
    end

    it "sends 'trial will end' email" do
      expect { Site.send_trial_will_end }.to change(ActionMailer::Base.deliveries, :size).by(@sites_in_trial.size)
    end

    it "doesn't send 'trial will end' email" do
      Timecop.travel(1.day.from_now) { expect { Site.send_trial_will_end }.to_not change(ActionMailer::Base.deliveries, :size) }
    end
  end

end
