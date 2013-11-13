require 'spec_helper'

describe SiteAdminStatsTrend do

  context "with a bunch of different site_stat" do
    before {
      create(:site_admin_stats_trend, d: 3.days.ago.midnight)
      allow(SiteAdminStat).to receive(:global_day_stat).with(2.days.ago.midnight) { { al: { m: 2 }, st: { w: 2 } } }
      allow(SiteAdminStat).to receive(:global_day_stat).with(1.days.ago.midnight) { { al: { m: 1 }, st: { w: 1 } } }
    }

    describe ".create_trends" do
      it "creates site_stats stats for the last 5 days" do
        described_class.create_trends
        expect(described_class.count).to eq 3
      end

      it "creates site_stats stats for the last day" do
        described_class.create_trends
        trend = described_class.last
        expect(trend.al).to eq({ "m" => 1 })
        expect(trend.st).to eq({ "w" => 1 })
      end
    end
  end

  describe '.json' do
    before do
      create(:site_admin_stats_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('al') }
    it { expect(subject[0]).to have_key('st') }
    it { expect(subject[0]).to have_key('lo') }
  end

end
