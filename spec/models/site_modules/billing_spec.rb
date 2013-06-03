require 'spec_helper'

shared_context 'site with a paid invoice' do
  before { create(:paid_invoice, site: @site) }
end

describe SiteModules::Billing, :addons do
  let(:site) { create(:site) }
  before do
    @site = site
  end
  subject { @site }

  describe '#invoices_open?' do
    include_context 'site with a paid invoice'
    context 'with only paid invoices' do
      its(:invoices_open?) { should be_false }
    end
    context 'with a failed invoice' do
      before { create(:invoice, site: site) }
      its(:invoices_open?) { should be_true }
    end
  end

  describe '#invoices_failed?' do
    include_context 'site with a paid invoice'
    context 'with only paid invoices' do
      its(:invoices_failed?) { should be_false }
    end
    context 'with a failed invoice' do
      before { create(:failed_invoice, site: site) }
      its(:invoices_failed?) { should be_true }
    end
  end

  describe '#invoices_waiting?' do
    include_context 'site with a paid invoice'
    context 'with only paid invoices' do
      its(:invoices_waiting?) { should be_false }
    end
    context 'with a failed invoice' do
      before { create(:waiting_invoice, site: site) }
      its(:invoices_waiting?) { should be_true }
    end
  end

  describe '#refunded?' do
    before do
      @site_refunded1     = create(:site, refunded_at: Time.now.utc).tap { |s| s.archive! }
      @site_not_refunded1 = create(:site, refunded_at: Time.now.utc)
      @site_not_refunded2 = create(:site, refunded_at: nil).tap { |s| s.archive! }
    end

    specify { @site_refunded1.should be_refunded }
    specify { @site_not_refunded1.should_not be_refunded }
    specify { @site_not_refunded2.should_not be_refunded }
  end
end
