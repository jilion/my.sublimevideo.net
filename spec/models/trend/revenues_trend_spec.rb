require 'spec_helper'

describe RevenuesTrend do

  context "with a bunch of different billable item activities", :addons do
    let(:paid_design) { create(:design, price: 999, name: 'foo') }
    before do
      site = create(:site)

      create(:billable_item_activity, site: site, item: paid_design, created_at: 5.days.ago.midnight, state: 'subscribed')
      create(:billable_item_activity, site: site, item: @stats_addon_plan_2, created_at: 5.days.ago.midnight, state: 'subscribed')

      create(:billable_item_activity, site: site, item: @stats_addon_plan_2, created_at: 3.days.ago.midnight, state: 'canceled')
      create(:billable_item_activity, site: site, item: @support_addon_plan_2, created_at: 3.days.ago.midnight, state: 'subscribed')

      create(:billable_item_activity, site: site, item: @logo_addon_plan_2, created_at: 2.days.ago.midnight, state: 'subscribed')

      create(:billable_item_activity, site: site, item: @support_addon_plan_2, created_at: 1.day.ago.midnight, state: 'canceled')
      create(:billable_item_activity, site: site, item: @logo_addon_plan_3, created_at: 1.day.ago.midnight, state: 'trial')
    end

    describe '.create_trends' do
      before do
        described_class.create_trends
      end

      it 'creates revenues_stats stats for the last 5 days' do
        described_class.count.should eq 5
      end

      it 'creates revenues_stats stats for 5 days ago' do
        billings_stat = described_class.all.entries[0]
        billings_stat['d'].should eq 5.days.ago.midnight
        billings_stat['r'].should == {}
      end

      it 'creates revenues_stats stats for 4 days ago' do
        billings_stat = described_class.all.entries[1]
        billings_stat['d'].should eq 4.days.ago.midnight
        billings_stat['r'].should == {}
      end

      it 'creates revenues_stats stats for 3 days ago' do
        billings_stat = described_class.all.entries[2]
        billings_stat['d'].should eq 3.days.ago.midnight
        billings_stat['r'].should == {}
      end

      it 'creates revenues_stats stats for 2 days ago' do
        billings_stat = described_class.all.entries[3]
        billings_stat['d'].should eq 2.days.ago.midnight
        billings_stat['r'].should == {}
      end

      it 'creates revenues_stats stats for 1 day ago' do
        billings_stat = described_class.all.entries[4]
        billings_stat['d'].should eq 1.day.ago.midnight
        billings_stat['r'].should == {}
      end
    end
  end

  describe '.json' do
    before do
      create(:revenues_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    its(:size) { should eq 1 }
    it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    it { subject[0].should have_key('r') }
  end

end
