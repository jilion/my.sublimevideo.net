require 'spec_helper'

describe SiteAdminStatsTrend do

  context "with a bunch of different site_stat" do
    before {
      create(:site_admin_stats_trend, d: 3.days.ago.midnight)
      SiteAdminStat.stub(:global_day_stat).with(2.days.ago.midnight) { { al: { m: 2 }, st: { w: 2 } } }
      SiteAdminStat.stub(:global_day_stat).with(1.days.ago.midnight) { { al: { m: 1 }, st: { w: 1 } } }
    }

    describe ".create_trends" do
      it "creates site_stats stats for the last 5 days" do
        described_class.create_trends
        described_class.count.should eq 3
      end

      it "creates site_stats stats for the last day" do
        described_class.create_trends
        trend = described_class.last
        trend.al.should eq({ "m" => 1 })
        trend.st.should eq({ "w" => 1 })
      end
    end
  end

  describe '.json' do
    before do
      create(:site_admin_stats_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    its(:size) { should eq 1 }
    it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    it { subject[0].should have_key('al') }
    it { subject[0].should have_key('st') }
    it { subject[0].should have_key('lo') }
  end

end
