require 'spec_helper'

describe Stats::SalesStat do

  context "with a bunch of different invoices" do

    before do
      site = create(:site)
      @plus_monthly_plan    = create(:plan, name: 'plus', cycle: 'month')
      @premium_monthly_plan = create(:plan, name: 'premium', cycle: 'month')
      @plus_yearly_plan     = create(:plan, name: 'plus', cycle: 'year')
      @premium_yearly_plan  = create(:plan, name: 'premium', cycle: 'year')

      create(:invoice, state: 'paid', paid_at: 5.days.ago, site: site, renew: false, invoice_items: [create(:plan_invoice_item, item: @plus_monthly_plan)], amount: 1)
      create(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: false, invoice_items: [create(:plan_invoice_item, item: @plus_monthly_plan)], amount: 2)
      create(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: false, invoice_items: [create(:plan_invoice_item, item: @plus_yearly_plan)], amount: 3)
      create(:invoice, state: 'paid', paid_at: Time.now.utc.midnight, site: site, renew: false, invoice_items: [create(:plan_invoice_item, item: @premium_monthly_plan)], amount: 4)
      create(:invoice, state: 'failed', site: site, renew: false, invoice_items: [create(:plan_invoice_item, item: @plus_yearly_plan)], amount: 5)

      create(:invoice, state: 'paid', paid_at: 5.days.ago, site: site, renew: true, invoice_items: [create(:plan_invoice_item, item: @plus_monthly_plan)], amount: 6)
      create(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: true, invoice_items: [create(:plan_invoice_item, item: @premium_monthly_plan)], amount: 7)
      create(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: true, invoice_items: [create(:plan_invoice_item, item: @premium_monthly_plan)], amount: 8)
      create(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: true, invoice_items: [create(:plan_invoice_item, item: @premium_yearly_plan)], amount: 9)
      create(:invoice, state: 'paid', paid_at: Time.now.utc.midnight, site: site, renew: true, invoice_items: [create(:plan_invoice_item, item: @premium_yearly_plan)], amount: 10)
      create(:invoice, state: 'canceled', site: site, renew: true, invoice_items: [create(:plan_invoice_item, item: @premium_yearly_plan)], amount: 11)
    end

    describe ".create_stats" do
      it "creates sales_stats stats for the last 5 days" do
        described_class.create_stats
        described_class.count.should eq 5
      end

      it "creates sales_stats stats for the last day" do
        described_class.create_stats
        sales_stat = described_class.last
        sales_stat["d"].should eq 1.day.ago.midnight
        sales_stat["ne"].should == {
          'plus' => { "m" => 2, "y" => 3 }
        }
        sales_stat["re"].should == {
          'premium' => { "m" => 7+8, "y" => 9 }
        }
      end
    end

  end

end
