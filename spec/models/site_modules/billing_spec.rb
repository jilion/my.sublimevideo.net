require 'spec_helper'

describe SiteModules::Billing do

  describe 'Instance Methods', :addons do

    describe '#invoices_open?' do
      let(:site) { create(:site) }

      context "with no options" do
        it "should be true if invoice have the renew flag == false" do
          invoice = create(:invoice, site: site, renew: false)
          invoice.renew.should be_false
          site.invoices_open?.should be_true
        end

        it "should be true if invoice have the renew flag == true" do
          invoice = create(:invoice, site: site, renew: true)
          invoice.renew.should be_true
          site.invoices_open?.should be_true
        end
      end
    end # #invoices_open?

    describe '#invoices_failed?' do
      subject do
        site = create(:site)
        create(:failed_invoice, site: site)
        site
      end

      its(:invoices_failed?) { should be_true }
    end # #invoices_failed?

    describe '#invoices_waiting?' do
      subject do
        site = create(:site)
        create(:waiting_invoice, site: site)
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

  end # Instance Methods

end
