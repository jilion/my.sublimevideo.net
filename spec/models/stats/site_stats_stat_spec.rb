require 'spec_helper'

describe Stats::SiteStatsStat do

  context "with a bunch of different site_stat" do

    describe ".create_stats" do
      context "with some Stat::Site in db" do
        before(:each) do
          Factory.create(:site_stat, d: 5.days.ago.midnight, pv: {}, vv: { e: 2 }, bp: {}, md: {})
          Factory.create(:site_stat, d: 1.day.ago.midnight, pv: {}, vv: { e: 4 }, bp: {}, md: { h: { d: 2, m: 1 }, f: { d: 1 } })
          Factory.create(:site_stat, d: 1.day.ago.midnight, pv: {}, vv: { e: 3 }, bp: {}, md: { h: { d: 1 }, f: { m: 1 } })
          Factory.create(:site_stat, d: 1.day.ago.midnight, pv: {}, vv: {}, bp: {}, md: { f: { d: 1 } })
          Factory.create(:site_stat, d: Time.now.midnight, pv: {}, vv: { e: 6 }, bp: {}, md: {})
        end

        it "should create site_stats stats for the last 5 days" do
          described_class.create_stats
          described_class.count.should eq 5
          site_stats_stat = described_class.last
          site_stats_stat.vv.should eq({ "e" => 7 })
          site_stats_stat.md.should eq({ "h" => { "d" => 3, "m" => 1 }, "f" => { "d" => 2, "m" => 1 } })
        end
      end

      it "should create site_stats stats for the last 2 days" do
        described_class.create(d: 2.days.ago.midnight, pv: {}, vv: {}, bp: {}, md: {})
        described_class.create_stats
        described_class.count.should eq 1 + 2
      end
    end
  end

end
