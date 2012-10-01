require 'spec_helper'

describe Stats::SalesStat do

  context "with a bunch of different invoices" do

    before do
      site = create(:site)
      @plus_monthly_plan    = create(:plan, name: 'plus', cycle: 'month')
      @premium_monthly_plan = create(:plan, name: 'premium', cycle: 'month')
      @plus_yearly_plan     = create(:plan, name: 'plus', cycle: 'year')
      @premium_yearly_plan  = create(:plan, name: 'premium', cycle: 'year')

      i = build(:invoice, state: 'paid', paid_at: 5.days.ago, site: site, renew: false, amount: 1)
      create(:plan_invoice_item, item: @plus_monthly_plan, invoice: i)
      i.save

      i = build(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: false, amount: 2)
      create(:plan_invoice_item, item: @plus_monthly_plan, invoice: i)
      i.save
      i = build(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: false, amount: 3)
      create(:plan_invoice_item, item: @plus_yearly_plan, invoice: i)
      i.save

      i = build(:invoice, state: 'paid', paid_at: Time.now.utc.midnight, site: site, renew: false, amount: 4)
      create(:plan_invoice_item, item: @premium_monthly_plan, invoice: i)
      i.save

      i = build(:invoice, state: 'failed', site: site, renew: false, amount: 5)
      create(:plan_invoice_item, item: @plus_yearly_plan, invoice: i)
      i.save

      i = build(:invoice, state: 'paid', paid_at: 5.days.ago, site: site, renew: true, amount: 6)
      create(:plan_invoice_item, item: @plus_monthly_plan, invoice: i)
      i.save

      i = build(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: true, amount: 7)
      create(:plan_invoice_item, item: @premium_monthly_plan, invoice: i)
      i.save
      i = build(:invoice, state: 'paid', paid_at: 1.day.ago.midnight, site: site, renew: true, amount: 8)
      create(:plan_invoice_item, item: @premium_yearly_plan, invoice: i)
      i.save

      i = build(:invoice, state: 'paid', paid_at: Time.now.utc.midnight, site: site, renew: true, amount: 9)
      create(:plan_invoice_item, item: @premium_monthly_plan, invoice: i)
      i.save

      i = build(:invoice, state: 'canceled', site: site, renew: true, amount: 5)
      create(:plan_invoice_item, item: @plus_yearly_plan, invoice: i)
      i.save
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
          'premium' => { "m" => 7, "y" => 8 }
        }
      end
    end

  end

end
