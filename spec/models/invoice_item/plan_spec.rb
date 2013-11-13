require 'spec_helper'

describe InvoiceItem::Plan do

  context "Factory" do
    let(:invoice) { create(:invoice) }
    let(:invoice_item) { create(:plan_invoice_item) }
    subject { invoice_item }

    describe '#invoice' do
      subject { super().invoice }
      it   { should be_nil }
    end

    describe '#type' do
      subject { super().type }
      it      { should eq 'InvoiceItem::Plan' }
    end

    describe '#item_type' do
      subject { super().item_type }
      it { should eq 'Plan' }
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
# Table name: plans
#
#  created_at           :datetime
#  cycle                :string(255)
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  price                :integer
#  stats_retention_days :integer
#  support_level        :integer          default(0)
#  token                :string(255)
#  updated_at           :datetime
#  video_views          :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

