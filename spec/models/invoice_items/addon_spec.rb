require 'spec_helper'

describe InvoiceItems::Addon do

  context "Factory" do
    let(:invoice_item) { create(:addon_invoice_item) }
    subject { invoice_item }

    its(:invoice)   { should be_nil }
    its(:type)      { should eq 'InvoiceItems::Addon' }
    its(:item_type) { should eq 'Addons::Addon' }
    its(:item_id)   { should be_present }
    specify         { subject.started_at.to_i.should eq Time.now.utc.beginning_of_month.to_i }
    specify         { subject.ended_at.to_i.should eq Time.now.utc.end_of_month.to_i }
    its(:price)     { should be_present }
    its(:amount)    { should be_present }

    it { should be_valid }
  end # Factory

end
