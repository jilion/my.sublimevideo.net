require 'spec_helper'

describe Stats::SiteStatsStat do

  describe ".delay_create_site_stats_stats" do
    it "should delay create_site_stats_stats if not already delayed" do
      expect { described_class.delay_create_site_stats_stats }.to change(Delayed::Job.where(:handler.matches => '%Stats::SiteStatsStat%create_site_stats_stats%'), :count).by(1)
    end

    it "should not delay create_site_stats_stats if already delayed" do
      described_class.delay_create_site_stats_stats
      expect { described_class.delay_create_site_stats_stats }.to_not change(Delayed::Job.where(:handler.matches => '%Stats::SiteStatsStat%create_site_stats_stats%'), :count)
    end

    it "should delay create_site_stats_stats for next day" do
      described_class.delay_create_site_stats_stats
      Delayed::Job.last.run_at.should eq (Time.now.utc.tomorrow.midnight + 5.minutes)
    end
  end

  context "with a bunch of different site_stat" do
    before(:each) do
      Factory.create(:site_stat, vv: { e: 2 }).tap { |ss| ss.update_attribute(:d, 5.days.ago.midnight) }
      Factory.create(:site_stat, vv: { e: 4 }, md: { h: { d: 2, m: 1 }, f: { d: 1 } }).tap { |ss| ss.update_attribute(:d, 1.day.ago.midnight) }
      Factory.create(:site_stat, vv: { e: 3 }, md: { h: { d: 1 }, f: { m: 1 } }).tap { |ss| ss.update_attribute(:d, 1.day.ago.midnight) }
      Factory.create(:site_stat, md: { f: { d: 1 } }).tap { |ss| ss.update_attribute(:d, 1.day.ago.midnight) }
      Factory.create(:site_stat, vv: { e: 6 }).tap { |ss| ss.update_attribute(:d, Time.now.midnight) }
    end

    describe ".create_site_stats_stats" do

      it "should delay itself" do
        described_class.should_receive(:delay_create_site_stats_stats)
        described_class.create_site_stats_stats
      end

      it "should create site_stats stats for the last 5 days" do
        described_class.create_site_stats_stats
        described_class.count.should eq 5
        site_stats_stat = described_class.last
        site_stats_stat.vv.should eq({ "e" => 7 })
        site_stats_stat.md.should eq({ "h" => { "d" => 3, "m" => 1 }, "f" => { "d" => 2, "m" => 1 } })
      end

      it "should create site_stats stats for the last 2 days" do
        described_class.create(d: 2.days.ago.midnight)
        described_class.create_site_stats_stats
        described_class.count.should eq 1 + 2
      end
    end
  end

end
