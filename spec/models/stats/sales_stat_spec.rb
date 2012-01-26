require 'spec_helper'

describe Stats::SalesStat do

  describe ".delay_create_sales_stats" do
    it "should delay create_sites_stats if not already delayed" do
      expect { described_class.delay_create_sales_stats }.to change(Delayed::Job.where(:handler.matches => '%Stats::SalesStat%create_sales_stats%'), :count).by(1)
    end

    it "should not delay create_sales_stats if already delayed" do
      described_class.delay_create_sales_stats
      expect { described_class.delay_create_sales_stats }.to_not change(Delayed::Job.where(:handler.matches => '%Stats::SalesStat%create_sales_stats%'), :count)
    end

    it "should delay create_sales_stats for next day" do
      described_class.delay_create_sales_stats
      Delayed::Job.last.run_at.should eq Time.now.utc.tomorrow.midnight
    end
  end

  context "with a bunch of different invoices" do
    before(:each) do
      site = Factory.create(:site)
      @plus_monthly_plan    = @paid_plan
      @premium_monthly_plan = Factory.create(:plan, name: 'premium', cycle: 'month')
      @plus_yearly_plan     = Factory.create(:plan, name: 'plus', cycle: 'year')
      @premium_yearly_plan  = Factory.create(:plan, name: 'premium', cycle: 'year')

      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: false, invoice_items: [Factory.create(:plan_invoice_item, item: @plus_monthly_plan)], amount: 1)
      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: false, invoice_items: [Factory.create(:plan_invoice_item, item: @plus_monthly_plan)], amount: 2)
      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: false, invoice_items: [Factory.create(:plan_invoice_item, item: @plus_yearly_plan)], amount: 4)
      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: false, invoice_items: [Factory.create(:plan_invoice_item, item: @premium_monthly_plan)], amount: 3)
      Factory.create(:invoice, state: 'failed', site: site, renew: false, invoice_items: [Factory.create(:plan_invoice_item, item: @plus_yearly_plan)], amount: 5)

      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: true, invoice_items: [Factory.create(:plan_invoice_item, item: @plus_monthly_plan)], amount: 6)
      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: true, invoice_items: [Factory.create(:plan_invoice_item, item: @premium_monthly_plan)], amount: 7)
      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: true, invoice_items: [Factory.create(:plan_invoice_item, item: @premium_monthly_plan)], amount: 8)
      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: true, invoice_items: [Factory.create(:plan_invoice_item, item: @premium_yearly_plan)], amount: 9)
      Factory.create(:invoice, state: 'paid', paid_at: Time.now.utc.yesterday, site: site, renew: true, invoice_items: [Factory.create(:plan_invoice_item, item: @premium_yearly_plan)], amount: 10)
      Factory.create(:invoice, state: 'canceled', site: site, renew: true, invoice_items: [Factory.create(:plan_invoice_item, item: @premium_yearly_plan)], amount: 11)
    end

    describe ".create_sales_stats" do

      it "should delay itself" do
        described_class.should_receive(:delay_create_sales_stats)
        described_class.create_sales_stats
      end

      it "should create sites stats for states & plans" do
        described_class.create_sales_stats
        described_class.count.should eq 1
        sales_stat = described_class.last
        sales_stat["ne"].should == {
          'plus' => { "m" => 1+2, "y" => 4 },
          'premium' => { "m" => 3 }
        }
        sales_stat["re"].should == {
          'plus' => { "m" => 6 },
          'premium' => { "m" => 7+8, "y" => 9+10 }
        }
      end
    end
  end

end
