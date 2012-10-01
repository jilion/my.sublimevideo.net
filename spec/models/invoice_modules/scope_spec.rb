require 'spec_helper'

describe InvoiceModules::Scope do
  let(:site) { create(:new_site) }
  let(:refunded_site) { create(:new_site, refunded_at: Time.now.utc) }
  before do

    @open_invoice     = create(:invoice, site: site, created_at: 48.hours.ago)
    @failed_invoice   = create(:failed_invoice, site: site, created_at: 25.hours.ago)
    @waiting_invoice  = create(:waiting_invoice, site: site, created_at: 18.hours.ago)
    @paid_invoice     = create(:paid_invoice, site: site, created_at: 16.hours.ago)
    @canceled_invoice = create(:canceled_invoice, site: site, created_at: 14.hours.ago)
    @refunded_invoice = create(:paid_invoice, site: refunded_site, created_at: 14.hours.ago)

    @open_invoice.should be_open
    @failed_invoice.should be_failed
    @waiting_invoice.should be_waiting
    @paid_invoice.should be_paid
    @canceled_invoice.should be_canceled
    @refunded_invoice.should be_refunded
  end

  describe ".between" do
    specify { Invoice.between(created_at: 24.hours.ago..15.hours.ago).order(:id).should eq [@waiting_invoice, @paid_invoice] }
  end

  describe ".open" do
    specify { Invoice.open.order(:id).should eq [@open_invoice] }
  end

  describe ".paid" do
    specify { Invoice.paid.order(:id).should eq [@paid_invoice] }
  end

  describe ".refunded" do
    specify { Invoice.refunded.order(:id).should eq [@refunded_invoice] }
  end

  describe ".failed" do
    specify { Invoice.failed.order(:id).should eq [@failed_invoice] }
  end

  describe ".waiting" do
    specify { Invoice.waiting.order(:id).should eq [@waiting_invoice] }
  end

  describe ".open_or_failed" do
    specify { Invoice.open_or_failed.order(:id).should eq [@open_invoice, @failed_invoice] }
  end

  describe ".not_canceled" do
    specify { Invoice.not_canceled.order(:id).should eq [@open_invoice, @failed_invoice, @waiting_invoice, @paid_invoice, @refunded_invoice] }
  end

  describe ".not_paid" do
    specify { Invoice.not_paid.order(:id).should eq [@open_invoice, @failed_invoice, @waiting_invoice] }
  end

end

# == Schema Information
#
# Table name: invoices
#
#  id                       :integer         not null, primary key
#  site_id                  :integer
#  reference                :string(255)
#  state                    :string(255)
#  customer_full_name       :string(255)
#  customer_email           :string(255)
#  customer_country         :string(255)
#  customer_company_name    :string(255)
#  site_hostname            :string(255)
#  amount                   :integer
#  vat_rate                 :float
#  vat_amount               :integer
#  invoice_items_amount     :integer
#  invoice_items_count      :integer         default(0)
#  transactions_count       :integer         default(0)
#  created_at               :datetime
#  updated_at               :datetime
#  paid_at                  :datetime
#  last_failed_at           :datetime
#  renew                    :boolean         default(FALSE)
#  balance_deduction_amount :integer         default(0)
#  customer_billing_address :text
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#
