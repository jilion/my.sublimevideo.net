require 'spec_helper'

describe Stats::RevenuesStat do

  context "with a bunch of different billable item activities", :addons do
    let(:paid_design) { create(:app_design, price: 999, name: 'foo') }
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

    describe '.create_stats' do
      before do
        described_class.create_stats
      end

      it 'creates revenues_stats stats for the last 5 days' do
        described_class.count.should eq 5
      end

      it 'creates revenues_stats stats for 5 days ago' do
        billings_stat = described_class.all.entries[0]
        billings_stat['d'].should eq 5.days.ago.midnight
        billings_stat['r'].should == {
          'design' => { 'foo' => (paid_design.price.to_f / Time.days_in_month(4.days.ago.month, 4.days.ago.year)).round },
          'stats' => { 'realtime' => (@stats_addon_plan_2.price.to_f / Time.days_in_month(4.days.ago.month, 4.days.ago.year)).round }
        }
      end

      it 'creates revenues_stats stats for 4 days ago' do
        billings_stat = described_class.all.entries[1]
        billings_stat['d'].should eq 4.days.ago.midnight
        billings_stat['r'].should == {
          'design' => { 'foo' => (paid_design.price.to_f / Time.days_in_month(4.days.ago.month, 4.days.ago.year)).round },
          'stats' => { 'realtime' => (@stats_addon_plan_2.price.to_f / Time.days_in_month(4.days.ago.month, 4.days.ago.year)).round }
        }
      end

      it 'creates revenues_stats stats for 3 days ago' do
        billings_stat = described_class.all.entries[2]
        billings_stat['d'].should eq 3.days.ago.midnight
        billings_stat['r'].should == {
          'design' => { 'foo' => (paid_design.price.to_f / Time.days_in_month(4.days.ago.month, 4.days.ago.year)).round },
          'support' => { 'vip' => (@support_addon_plan_2.price.to_f / Time.days_in_month(2.days.ago.month, 2.days.ago.year)).round }
        }
      end

      it 'creates revenues_stats stats for 2 days ago' do
        billings_stat = described_class.all.entries[3]
        billings_stat['d'].should eq 2.days.ago.midnight
        billings_stat['r'].should == {
          'design' => { 'foo' => (paid_design.price.to_f / Time.days_in_month(2.days.ago.month, 2.days.ago.year)).round },
          'support' => { 'vip' => (@support_addon_plan_2.price.to_f / Time.days_in_month(2.days.ago.month, 2.days.ago.year)).round },
          'logo' => { 'disabled' => (@logo_addon_plan_2.price.to_f / Time.days_in_month(1.day.ago.month, 1.day.ago.year)).round }
        }
      end

      it 'creates revenues_stats stats for 1 day ago' do
        billings_stat = described_class.all.entries[4]
        billings_stat['d'].should eq 1.day.ago.midnight
        billings_stat['r'].should == {
          'design' => { 'foo' => (paid_design.price.to_f / Time.days_in_month(2.days.ago.month, 2.days.ago.year)).round },
          'logo' => { 'disabled' => (@logo_addon_plan_2.price.to_f / Time.days_in_month(1.day.ago.month, 1.day.ago.year)).round }
        }
      end
    end

  end

end
