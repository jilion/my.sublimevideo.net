require 'spec_helper'

describe Stats::SalesStat do

  context "with a bunch of different invoices", :addons do
    before do
      site = create(:site)
      @plus_monthly_plan    = create(:plan, name: 'plus', cycle: 'month')
      @premium_monthly_plan = create(:plan, name: 'premium', cycle: 'month')
      @plus_yearly_plan     = create(:plan, name: 'plus', cycle: 'year')
      @premium_yearly_plan  = create(:plan, name: 'premium', cycle: 'year')

      build(:paid_invoice, paid_at: 5.days.ago, site: site, renew: false, amount: 1).tap { |i|
        create(:addon_plan_invoice_item, item: @stats_addon_plan_2, invoice: i)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false, amount: 12).tap { |i|
        create(:app_design_invoice_item, item: @twit_design, invoice: i)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false, amount: 2).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_2, invoice: i)
      }.save
      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false, amount: 3).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_3, invoice: i)
      }.save

      build(:paid_invoice, paid_at: Time.now.utc.midnight, site: site, renew: false, amount: 4).tap { |i|
        create(:addon_plan_invoice_item, item: @support_addon_plan_2, invoice: i)
      }.save

      build(:failed_invoice, site: site, renew: false, amount: 5).tap { |i|
        create(:addon_plan_invoice_item, item: @stats_addon_plan_2, invoice: i)
      }.save

      build(:paid_invoice, paid_at: 5.days.ago, site: site, renew: true, amount: 6).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_2, invoice: i)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: true, amount: 7).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_3, invoice: i)
      }.save
      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: true, amount: 8).tap { |i|
        create(:addon_plan_invoice_item, item: @support_addon_plan_2, invoice: i)
      }.save

      build(:paid_invoice, paid_at: Time.now.utc.midnight, site: site, renew: true, amount: 9).tap { |i|
        create(:addon_plan_invoice_item, item: @stats_addon_plan_2, invoice: i)
      }.save

      build(:canceled_invoice, site: site, renew: true, amount: 5).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_2, invoice: i)
      }.save
    end

    describe '.create_stats' do
      it 'creates sales_stats stats for the last 5 days' do
        described_class.create_stats
        described_class.count.should eq 5
      end

      it 'creates sales_stats stats for the last day' do
        described_class.create_stats
        sales_stat = described_class.last
        sales_stat["d"].should eq 1.day.ago.midnight
        sales_stat["ne"].should == {
          'design' => { 'twit' => 12 },
          'logo' => { 'disabled' => 2, 'custom' => 3 }
        }
        sales_stat["re"].should == {
          'logo' => { 'custom' => 7 },
          'support' => { 'vip' => 8 }
        }
      end
    end

  end

end
