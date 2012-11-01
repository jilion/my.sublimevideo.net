require 'spec_helper'

describe Stats::SalesStat do

  context "with a bunch of different invoices", :addons do
    before do
      site = create(:site)
      @plus_monthly_plan    = create(:plan, name: 'plus', cycle: 'month')
      @premium_monthly_plan = create(:plan, name: 'premium', cycle: 'month')
      @plus_yearly_plan     = create(:plan, name: 'plus', cycle: 'year')
      @premium_yearly_plan  = create(:plan, name: 'premium', cycle: 'year')

      build(:paid_invoice, paid_at: 5.days.ago, site: site, renew: false).tap { |i|
        create(:addon_plan_invoice_item, item: @stats_addon_plan_2, invoice: i, amount: 1)
      }.save

      # useful records
      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false).tap { |i|
        create(:app_design_invoice_item, item: @twit_design, invoice: i, amount: 2)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false).tap { |i|
        create(:app_design_invoice_item, item: @twit_design, invoice: i, amount: 2)
        create(:addon_plan_invoice_item, item: @logo_addon_plan_2, invoice: i, amount: 3)
      }.save
      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false).tap { |i|
        create(:app_design_invoice_item, item: @twit_design, invoice: i, amount: 2)
        create(:addon_plan_invoice_item, item: @logo_addon_plan_3, invoice: i, amount: 4)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: true).tap { |i|
        create(:app_design_invoice_item, item: @twit_design, invoice: i, amount: 2)
        create(:addon_plan_invoice_item, item: @logo_addon_plan_3, invoice: i, amount: 4)
      }.save
      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: true).tap { |i|
        create(:app_design_invoice_item, item: @twit_design, invoice: i, amount: 2)
        create(:addon_plan_invoice_item, item: @support_addon_plan_2, invoice: i, amount: 5)
      }.save
      # useful records

      build(:paid_invoice, paid_at: Time.now.utc.midnight, site: site, renew: false).tap { |i|
        create(:addon_plan_invoice_item, item: @support_addon_plan_2, invoice: i, amount: 4)
      }.save

      build(:failed_invoice, site: site, renew: false).tap { |i|
        create(:addon_plan_invoice_item, item: @stats_addon_plan_2, invoice: i, amount: 5)
      }.save

      build(:paid_invoice, paid_at: 5.days.ago, site: site, renew: true).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_2, invoice: i, amount: 6)
      }.save

      build(:paid_invoice, paid_at: Time.now.utc.midnight, site: site, renew: true).tap { |i|
        create(:addon_plan_invoice_item, item: @stats_addon_plan_2, invoice: i, amount: 9)
      }.save

      build(:canceled_invoice, site: site, renew: true).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_2, invoice: i, amount: 5)
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
          'design' => { 'twit' => 6 },
          'logo'   => { 'disabled' => 3, 'custom' => 4 }
        }
        sales_stat["re"].should == {
          'design'  => { 'twit' => 4 },
          'logo'    => { 'custom' => 4 },
          'support' => { 'vip' => 5 }
        }
      end
    end

  end

end
