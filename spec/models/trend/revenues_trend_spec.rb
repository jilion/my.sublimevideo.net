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
        expect(described_class.count).to eq 5
      end

      it 'creates revenues_stats stats for 5 days ago' do
        billings_stat = described_class.all.entries[0]
        expect(billings_stat['d']).to eq 5.days.ago.midnight
        expect(billings_stat['r']).to eq({
          'design' => { 'foo' => (paid_design.price.to_f * 12 / 365).round },
          'stats' => { 'realtime' => (@stats_addon_plan_2.price.to_f * 12 / 365).round }
        })
      end

      it 'creates revenues_stats stats for 4 days ago' do
        billings_stat = described_class.all.entries[1]
        expect(billings_stat['d']).to eq 4.days.ago.midnight
        expect(billings_stat['r']).to eq({
          'design' => { 'foo' => (paid_design.price.to_f * 12 / 365).round },
          'stats' => { 'realtime' => (@stats_addon_plan_2.price.to_f * 12 / 365).round }
        })
      end

      it 'creates revenues_stats stats for 3 days ago' do
        billings_stat = described_class.all.entries[2]
        expect(billings_stat['d']).to eq 3.days.ago.midnight
        expect(billings_stat['r']).to eq({
          'design' => { 'foo' => (paid_design.price.to_f * 12 / 365).round },
          'support' => { 'vip' => (@support_addon_plan_2.price.to_f * 12 / 365).round }
        })
      end

      it 'creates revenues_stats stats for 2 days ago' do
        billings_stat = described_class.all.entries[3]
        expect(billings_stat['d']).to eq 2.days.ago.midnight
        expect(billings_stat['r']).to eq({
          'design' => { 'foo' => (paid_design.price.to_f * 12 / 365).round },
          'support' => { 'vip' => (@support_addon_plan_2.price.to_f * 12 / 365).round },
          'logo' => { 'disabled' => (@logo_addon_plan_2.price.to_f * 12 / 365).round }
        })
      end

      it 'creates revenues_stats stats for 1 day ago' do
        billings_stat = described_class.all.entries[4]
        expect(billings_stat['d']).to eq 1.day.ago.midnight
        expect(billings_stat['r']).to eq({
          'design' => { 'foo' => (paid_design.price.to_f * 12 / 365).round },
          'logo' => { 'disabled' => (@logo_addon_plan_2.price.to_f * 12 / 365).round }
        })
      end
    end
  end

  describe '.json' do
    before do
      create(:revenues_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('r') }
  end

end
