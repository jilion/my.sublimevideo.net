require 'spec_helper'

describe Site::Recurring do

  describe ".delay_update_last_30_days_counters_for_not_archived_sites" do
    it "should delay update_last_30_days_counters_for_not_archived_sites if not already delayed" do
      expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.to \
      change(Delayed::Job.where(:handler.matches => '%Site%update_last_30_days_counters_for_not_archived_sites%'), :count).by(1)
    end

    it "should not delay update_last_30_days_counters_for_not_archived_sites if already delayed" do
      Site.delay_update_last_30_days_counters_for_not_archived_sites
      expect { Site.delay_update_last_30_days_counters_for_not_archived_sites }.to \
      change(Delayed::Job.where(:handler.matches => '%Site%update_last_30_days_counters_for_not_archived_sites%'), :count).by(0)
    end
  end

  describe ".update_last_30_days_counters_for_not_archived_sites" do
    it "should delay itself" do
      Site.should_receive(:delay_update_last_30_days_counters_for_not_archived_sites)
      Site.update_last_30_days_counters_for_not_archived_sites
    end

    it "should call update_last_30_days_counters on each non-archived sites" do
      @active_site = FactoryGirl.create(:site, state: 'active')
      FactoryGirl.create(:site_usage, site_id: @active_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)
      @archived_site = FactoryGirl.create(:site, state: 'archived')
      FactoryGirl.create(:site_usage, site_id: @archived_site.id, day: Time.utc(2011,1,15).midnight, main_player_hits: 6)

      Timecop.travel(Time.utc(2011,1,31, 12)) do
        Site.update_last_30_days_counters_for_not_archived_sites
        @active_site.reload.last_30_days_main_player_hits_total_count.should == 6
        @archived_site.reload.last_30_days_main_player_hits_total_count.should == 0
      end
    end
  end

end
