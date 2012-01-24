require 'spec_helper'

describe Stats::SiteUsagesStat do

  context "with a bunch of different site_usage" do
    before(:each) do
      site = Factory.create(:site)
      Factory.create(:site_usage, site_id: site.id, day: 5.days.ago.midnight, loader_hits: 2)
      Factory.create(:site_usage, site_id: site.id, day: 1.day.ago.midnight,  loader_hits: 8, ssl_loader_hits: 3, main_player_hits: 1, main_player_hits_cached: 1, extra_player_hits: 1, extra_player_hits_cached: 1, dev_player_hits: 1, dev_player_hits_cached: 1, invalid_player_hits: 1, invalid_player_hits_cached: 1)
      Factory.create(:site_usage, site_id: site.id, day: 1.day.ago.midnight,  loader_hits: 5, ssl_loader_hits: 2, main_player_hits: 1, main_player_hits_cached: 1, extra_player_hits: 1, extra_player_hits_cached: 1, dev_player_hits: 1, dev_player_hits_cached: 1, invalid_player_hits: 1, invalid_player_hits_cached: 1, flash_hits: 3, requests_s3: 4, traffic_s3: 123, traffic_voxcast: 231)
      Factory.create(:site_usage, site_id: site.id, day: 1.day.ago.midnight,  loader_hits: 0, ssl_loader_hits: 0, flash_hits: 3, requests_s3: 4, traffic_s3: 123, traffic_voxcast: 231)
      Factory.create(:site_usage, site_id: site.id, day: Time.now.midnight,   loader_hits: 2, ssl_loader_hits: 1)
    end

    describe ".create_site_usages_stats" do

      it "should delay itself" do
        described_class.should_receive(:delay_create_site_usages_stats)
        described_class.create_site_usages_stats
      end

      it "should create site_stats stats for the last 5 days" do
        described_class.create_site_usages_stats
        described_class.count.should eq 5
        site_usages_stat = described_class.last
        site_usages_stat.lh.should eq({ 'ns' => 8, 's' => 5 })
        site_usages_stat.ph.should eq({ 'm' => 2, 'mc' => 2, 'e' => 2, 'ec' => 2, 'd' => 2, 'dc' => 2, 'i' => 2, 'ic' => 2 })
        site_usages_stat.fh.should eq 6
        site_usages_stat.sr.should eq 8
        site_usages_stat.tr.should eq({ 's' => 246, 'v' => 462 })
      end

      it "should create site_stats stats for the last 2 days" do
        described_class.create(d: 2.days.ago.midnight)
        described_class.create_site_usages_stats
        described_class.count.should eq 1 + 1
      end

    end

  end

end
