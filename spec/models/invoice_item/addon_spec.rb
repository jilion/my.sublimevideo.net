require 'spec_helper'

describe InvoiceItem::AddonPlan do

  context "Factory" do
    let(:invoice_item) { create(:addon_plan_invoice_item) }
    subject { invoice_item }

    describe '#invoice' do
      subject { super().invoice }
      it   { should be_nil }
    end

    describe '#type' do
      subject { super().type }
      it      { should eq 'InvoiceItem::AddonPlan' }
    end

    describe '#item_type' do
      subject { super().item_type }
      it { should eq 'AddonPlan' }
    end

    describe '#item_id' do
      subject { super().item_id }
      it   { should be_present }
    end
    specify         { expect(subject.started_at.to_i).to eq Time.now.utc.beginning_of_month.to_i }
    specify         { expect(subject.ended_at.to_i).to eq Time.now.utc.end_of_month.to_i }

    describe '#price' do
      subject { super().price }
      it     { should be_present }
    end

    describe '#amount' do
      subject { super().amount }
      it    { should be_present }
    end

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

