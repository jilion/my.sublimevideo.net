require 'spec_helper'

describe InvoiceItem do

  context "Factory" do
    before(:all) { @invoice_item = FactoryGirl.create(:plan_invoice_item) }
    subject { @invoice_item }

    its(:invoice)   { should be_present }
    its(:site)      { should == @invoice_item.invoice.site }
    its(:user)      { should == @invoice_item.site.user }
    its(:type)      { should == 'InvoiceItem::Plan' }
    its(:item_type) { should == 'Plan' }
    its(:item_id)   { should be_present }
    specify { subject.started_at.to_i.should == Time.now.utc.beginning_of_month.to_i }
    specify { subject.ended_at.to_i.should == Time.now.utc.end_of_month.to_i }
    its(:price)     { should == 1000 }
    its(:amount)    { should == 1000 }

    it { should be_valid }
  end # Factory

  describe "Associations" do
    before(:all) { @invoice_item = FactoryGirl.create(:plan_invoice_item) }
    subject { @invoice_item }

    it { should belong_to :invoice }
    it { should belong_to :item }
  end # Associations

  describe "Validations" do
    [:invoice, :item].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:invoice) }
    it { should validate_presence_of(:item_type) }
    it { should validate_presence_of(:item_id) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }

    it { should validate_numericality_of(:price) }
    it { should validate_numericality_of(:amount) }
  end # Validations

end



# == Schema Information
#
# Table name: invoice_items
#
#  id                    :integer         not null, primary key
#  type                  :string(255)
#  invoice_id            :integer
#  item_type             :string(255)
#  item_id               :integer
#  started_at            :datetime
#  ended_at              :datetime
#  discounted_percentage :float
#  price                 :integer
#  amount                :integer
#  created_at            :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#

