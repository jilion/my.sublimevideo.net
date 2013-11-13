require 'fast_spec_helper'

require 'site_admin_stat'
require 'services/site_admin_stats_timeline_builder'

describe SiteAdminStatsTimelineBuilder do
  let(:site) { double("Site", token: 'abcd1234') }
  let(:builder) { SiteAdminStatsTimelineBuilder.new(site, days: 30) }

  let(:stat1) { double("SiteAdminStat", date: 1.days.ago.to_date, loads: { 'w' => 2, 'e' => 5}, starts: {}) }
  let(:stat2) { double("SiteAdminStat", date: 15.days.ago.to_date, starts: { 'w' => 4, 'e' => 3}, loads: {}) }
  let(:null_stat) { double("SiteAdminStat", loads: {}, starts: {}) }

  before {
    allow(SiteAdminStat).to receive(:all).with(site_token: site.token, days: 60) { [stat1, stat2] }
    allow(SiteAdminStat).to receive(:new) { null_stat }
  }

  describe "#loads" do
    describe "with all sites" do
      it "returns 30 stats array" do
        expect(builder.loads.size).to eq(30)
        expect(builder.loads.last).to eq 7
      end
    end
    describe "with only website sources" do
      it "returns 30 stats array" do
        expect(builder.loads(:website).size).to eq(30)
        expect(builder.loads(:website).last).to eq 2
      end
    end
  end

  describe "#starts" do
    describe "with all sites" do
      it "returns 30 stats array" do
        expect(builder.starts.size).to eq(30)
        expect(builder.starts[15]).to eq 7
      end
    end
    describe "with only external sources" do
      it "returns 30 stats array" do
        expect(builder.starts(:external).size).to eq(30)
        expect(builder.starts(:external)[15]).to eq 3
      end
    end
  end

end
