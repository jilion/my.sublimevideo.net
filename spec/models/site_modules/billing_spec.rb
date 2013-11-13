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
      describe '#invoices_open?' do
        subject { super().invoices_open? }
        it { should be_falsey }
      end
    end
    context 'with a failed invoice' do
      before { create(:invoice, site: site) }

      describe '#invoices_open?' do
        subject { super().invoices_open? }
        it { should be_truthy }
      end
    end
  end

  describe '#invoices_failed?' do
    include_context 'site with a paid invoice'
    context 'with only paid invoices' do
      describe '#invoices_failed?' do
        subject { super().invoices_failed? }
        it { should be_falsey }
      end
    end
    context 'with a failed invoice' do
      before { create(:failed_invoice, site: site) }

      describe '#invoices_failed?' do
        subject { super().invoices_failed? }
        it { should be_truthy }
      end
    end
  end

  describe '#invoices_waiting?' do
    include_context 'site with a paid invoice'
    context 'with only paid invoices' do
      describe '#invoices_waiting?' do
        subject { super().invoices_waiting? }
        it { should be_falsey }
      end
    end
    context 'with a failed invoice' do
      before { create(:waiting_invoice, site: site) }

      describe '#invoices_waiting?' do
        subject { super().invoices_waiting? }
        it { should be_truthy }
      end
    end
  end

  describe '#refunded?' do
    before do
      @site_refunded1     = create(:site, refunded_at: Time.now.utc).tap { |s| s.archive! }
      @site_not_refunded1 = create(:site, refunded_at: Time.now.utc)
      @site_not_refunded2 = create(:site, refunded_at: nil).tap { |s| s.archive! }
    end

    specify { expect(@site_refunded1).to be_refunded }
    specify { expect(@site_not_refunded1).not_to be_refunded }
    specify { expect(@site_not_refunded2).not_to be_refunded }
  end
end
