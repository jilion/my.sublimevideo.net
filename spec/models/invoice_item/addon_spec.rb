require 'spec_helper'

describe InvoiceItem::AddonPlan do

  context "Factory" do
    let(:invoice_item) { create(:addon_plan_invoice_item) }
    subject { invoice_item }

    its(:invoice)   { should be_nil }
    its(:type)      { should eq 'InvoiceItem::AddonPlan' }
    its(:item_type) { should eq 'AddonPlan' }
    its(:item_id)   { should be_present }
    specify         { subject.started_at.to_i.should eq Time.now.utc.beginning_of_month.to_i }
    specify         { subject.ended_at.to_i.should eq Time.now.utc.end_of_month.to_i }
    its(:price)     { should be_present }
    its(:amount)    { should be_present }

    it { should be_valid }
  end

end

# == Schema Information
#
# Table name: invoice_items
#
#  amount                :integer
#  created_at            :datetime         not null
#  deal_id               :integer
#  discounted_percentage :float
#  ended_at              :datetime
#  id                    :integer          not null, primary key
#  invoice_id            :integer
#  item_id               :integer
#  item_type             :string(255)
#  price                 :integer
#  started_at            :datetime
#  type                  :string(255)
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_invoice_items_on_deal_id                (deal_id)
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#

