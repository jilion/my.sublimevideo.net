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
      @sites_not_in_trial = [Factory.create(:site, trial_started_at: BusinessModel.days_for_trial.days.ago)]
      @sites_in_trial = []

      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        @sites_not_in_trial << Factory.create(:site, state: 'archived', trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
        @sites_not_in_trial << Factory.create(:site, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago, first_paid_plan_started_at: 2.months.ago)
        @sites_in_trial << Factory.create(:site, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
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

  describe ".delay_stop_stats_trial" do
    it "delays stop_stats_trial if not already delayed" do
      expect { Site.delay_stop_stats_trial }.to \
      change(Delayed::Job.where { handler =~ '%Site%stop_stats_trial%' }, :count).by(1)
    end

    it "doesn't delay stop_stats_trial if already delayed" do
      Site.delay_stop_stats_trial
      expect { Site.delay_stop_stats_trial }.not_to \
      change(Delayed::Job.where { handler =~ '%Site%stop_stats_trial%' }, :count)
    end
  end

  describe ".stop_stats_trial" do
    before(:all) do
      Site.delete_all
      @site_not_in_stats_trial = Factory.create(:site, plan_id: @free_plan.id, stats_trial_started_at: nil)
      @site_in_stats_trial = Factory.create(:site, plan_id: @free_plan.id, stats_trial_started_at: 7.days.ago)
      @worker.work_off # set_template("license")
      Timecop.travel(4.days.ago) do
        @site_no_more_in_stats_trial = Factory.create(:site, plan_id: @free_plan.id, stats_trial_started_at: 4.days.ago) # 8.days.ago with the Timecop.travel
        @worker.work_off # set_template("license")
      end
    end

    it "delays itself" do
      Site.should_receive(:delay_stop_stats_trial)
      Site.stop_stats_trial
    end

    it "removes r:true from site in stats trial licence" do
      Site.find(@site_not_in_stats_trial).license.read.should_not include('r:true')
      Site.find(@site_in_stats_trial).license.read.should include('r:true')
      Site.find(@site_no_more_in_stats_trial).license.read.should include('r:true')
      Site.stop_stats_trial
      @worker.work_off
      Site.find(@site_not_in_stats_trial).license.read.should_not include('r:true')
      Site.find(@site_in_stats_trial).license.read.should include('r:true')
      Site.find(@site_no_more_in_stats_trial).license.read.should_not include('r:true')
    end
  end

  describe ".delay_send_stats_trial_will_end" do
    it "delays send_stats_trial_will_end if not already delayed" do
      expect { Site.delay_send_stats_trial_will_end }.to \
      change(Delayed::Job.where { handler =~ '%Site%send_stats_trial_will_end%' }, :count).by(1)
    end

    it "doesn't delay send_stats_trial_will_end if already delayed" do
      Site.delay_send_stats_trial_will_end
      expect { Site.delay_send_stats_trial_will_end }.not_to \
      change(Delayed::Job.where { handler =~ '%Site%send_stats_trial_will_end%' }, :count)
    end
  end

  describe ".send_stats_trial_will_end" do
    before(:all) do
      Site.delete_all
      @site_not_in_stats_trial     = Factory.create(:site, plan_id: @free_plan.id, stats_trial_started_at: nil)
      @site_in_stats_trial         = Factory.create(:site, plan_id: @free_plan.id, stats_trial_started_at: 6.days.ago)
      @site_no_more_in_stats_trial = Factory.create(:site, plan_id: @free_plan.id, stats_trial_started_at: 8.days.ago)
    end

    it "delays itself" do
      Site.should_receive(:delay_send_stats_trial_will_end)
      Site.send_stats_trial_will_end
    end

    it "sends 'stats trial will end' email" do
      expect { Site.send_stats_trial_will_end }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end

    it "doesn't send 'stats trial will end' email" do
      Timecop.travel(1.day.from_now) { expect { Site.send_stats_trial_will_end }.to_not change(ActionMailer::Base.deliveries, :size) }
    end
  end

end
