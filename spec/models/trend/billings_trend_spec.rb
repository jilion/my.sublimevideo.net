require 'spec_helper'

describe BillingsTrend do

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
        create(:plan_invoice_item, item: @plus_monthly_plan, invoice: i, amount: 2)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false).tap { |i|
        create(:design_invoice_item, item: @twit_design, invoice: i, amount: 2)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false, balance_deduction_amount: 5).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_2, invoice: i, amount: 3)
        create(:design_invoice_item, item: @twit_design, invoice: i, amount: 2)
      }.save
      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: false, balance_deduction_amount: 2).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_3, invoice: i, amount: 4)
        create(:design_invoice_item, item: @twit_design, invoice: i, amount: 2)
      }.save

      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: true).tap { |i|
        create(:addon_plan_invoice_item, item: @logo_addon_plan_3, invoice: i, amount: 4)
        create(:design_invoice_item, item: @twit_design, invoice: i, amount: 2)
      }.save
      build(:paid_invoice, paid_at: 1.day.ago.midnight, site: site, renew: true, balance_deduction_amount: 2).tap { |i|
        create(:addon_plan_invoice_item, item: @support_addon_plan_2, invoice: i, amount: 5)
        create(:design_invoice_item, item: @twit_design, invoice: i, amount: 2)
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

    describe '.create_trends' do
      it 'creates billings_stats stats for the last 5 days' do
        described_class.create_trends
        expect(described_class.count).to eq 5
      end

      it 'creates billings_stats stats for the last day' do
        described_class.create_trends
        billings_stat = described_class.last
        expect(billings_stat["d"]).to eq 1.day.ago.midnight
        expect(billings_stat["ne"]).to eq({
          'plus' => { 'm' => 2 },
          'design' => { 'twit' => 4 },
          'logo'   => { 'disabled' => 0, 'custom' => 2 }
        })
        expect(billings_stat["re"]).to eq({
          'design'  => { 'twit' => 4 },
          'logo'    => { 'custom' => 4 },
          'support' => { 'vip' => 3 }
        })
      end
    end
  end

  describe '.json' do
    before do
      create(:billings_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('ne') }
    it { expect(subject[0]).to have_key('re') }
  end

end
