require 'spec_helper'

describe SiteModules::Billing do

  describe 'Instance Methods', :addons do

    describe '#invoices_open?' do
      let(:site) { create(:site) }

      context "with no options" do
        it "should be true if invoice have the renew flag == false" do
          invoice = create(:invoice, state: 'open', site: site, renew: false)
          invoice.renew.should be_false
          site.invoices_open?.should be_true
        end

        it "should be true if invoice have the renew flag == true" do
          invoice = create(:invoice, state: 'open', site: site, renew: true)
          invoice.renew.should be_true
          site.invoices_open?.should be_true
        end
      end
    end # #invoices_open?

    describe '#invoices_failed?' do
      subject do
        site = create(:site)
        create(:invoice, site: site , state: 'failed')
        site
      end

      its(:invoices_failed?) { should be_true }
    end # #invoices_failed?

    describe '#invoices_waiting?' do
      subject do
        site = create(:site)
        create(:invoice, site: site , state: 'waiting')
        site
      end

      its(:invoices_waiting?) { should be_true }
    end # #invoices_waiting?

    describe '#refunded?' do
      before do
        @site_refunded1     = create(:site, refunded_at: Time.now.utc).tap { |s| s.archive! }
        @site_not_refunded1 = create(:site, refunded_at: Time.now.utc)
        @site_not_refunded2 = create(:site, refunded_at: nil).tap { |s| s.archive! }
      end

      specify { @site_refunded1.should be_refunded }
      specify { @site_not_refunded1.should_not be_refunded }
      specify { @site_not_refunded2.should_not be_refunded }
    end # #refunded?

    describe '#last_paid_invoice' do
      let(:invoice) { create(:invoice, state: 'paid') }
      context "with the last paid invoice not refunded" do

        it "should return the last paid invoice" do
          invoice.site.invoices.should have(1).item
          invoice.site.last_paid_invoice.should eq invoice
        end
      end

      context "with the last paid invoice refunded" do
        before do
          invoice.site.invoices.should have(1).item
          invoice.site.update_attribute(:refunded_at, Time.now.utc)
        end

        it "returns nil" do
          invoice.site.refunded_at.should be_present
          invoice.site.last_paid_invoice.should be_nil
        end
      end
    end # #last_paid_invoice

    pending '#last_paid_plan' do
      context "site with no invoice" do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:last_paid_plan) { should be_nil }
      end

      context "site with at least one paid invoice" do
        before do
          @plan1 = create(:plan, price: 10_000)
          @plan2 = create(:plan, price: 5_000)
          @site  = create(:site_with_invoice, plan_id: @plan1.id)
          @site.plan_id = @plan2.id
        end

        it "should return the plan of the last InvoiceItem::Plan with an price > 0" do
          @site.last_paid_plan.should eq @plan1
        end
      end
    end # #last_paid_plan

    pending '#last_paid_plan_price' do
      context "site with no invoice" do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:last_paid_plan_price) { should eq 0 }
      end

      context "site with at least one paid invoice" do
        before do
          @plan1 = create(:plan, price: 10_000)
          @plan2 = create(:plan, price: 5_000)
          @site  = create(:site_with_invoice, plan_id: @plan1.id)
          @site.plan_id = @plan2.id
        end

        it "should return the price of the last InvoiceItem::Plan with an price > 0" do
          @site.last_paid_plan_price.should eq @plan1.price
        end
      end
    end # #last_paid_plan_price

  end # Instance Methods

end
