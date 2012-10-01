require 'spec_helper'

describe InvoiceItems::Plan do

  context "Factory" do
    let(:invoice) { create(:invoice) }
    let(:invoice_item) { create(:plan_invoice_item) }
    subject { invoice_item }

    its(:invoice)   { should be_nil }
    its(:type)      { should eq 'InvoiceItems::Plan' }
    its(:item_type) { should eq 'Plan' }
    its(:item_id)   { should be_present }
    specify         { subject.started_at.to_i.should eq Time.now.utc.beginning_of_month.to_i }
    specify         { subject.ended_at.to_i.should eq Time.now.utc.end_of_month.to_i }
    its(:price)     { should be_present }
    its(:amount)    { should be_present }

    it { should be_valid }
  end # Factory

end

# == Schema Information
#
# Table name: plans
#
#  created_at           :datetime         not null
#  cycle                :string(255)
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  price                :integer
#  stats_retention_days :integer
#  support_level        :integer          default(0)
#  token                :string(255)
#  updated_at           :datetime         not null
#  video_views          :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

