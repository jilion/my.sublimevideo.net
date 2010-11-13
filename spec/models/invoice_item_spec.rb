require 'spec_helper'

describe InvoiceItem do
  context "from factory" do
    set(:invoice_item_from_factory) { Factory(:invoice_item) }
    subject { invoice_item_from_factory }
    
    its(:site)                     { should be_present }
    its(:invoice)                  { should be_present }
    its(:item_type)                { should == 'Plan' }
    its(:item_id)                  { should be_present }
    # its(:started_on)               { should == Date.new(2010,1,1) }
    # its(:ended_on)                 { should == Date.new(2010,1,31) }
    its(:canceled_at)              { should be_nil }
    its(:price)                    { should == 100 }
    its(:overage_amount)           { should == 0 }
    its(:overage_price)            { should be_nil }
    its(:refund)                   { should == 0 }
    its(:refunded_invoice_item_id) { should be_nil }
    
    it { be_valid }
  end
  
  describe "associations" do
    set(:invoice_item_for_associations) { Factory(:invoice_item) }
    subject { invoice_item_for_associations }
    
    it { should belong_to :site }
    it { should belong_to :invoice }
    it { should belong_to :item }
    it { should belong_to :refunded_invoice_item }
  end
  
  describe "scopes" do
    before(:all) do
      @not_canceled_invoice_item = Factory(:invoice_item)
      @canceled_invoice_item = Factory(:invoice_item, :canceled_at => Time.now.utc)
    end
    
    specify do
      not_canceled_invoice_items = InvoiceItem.not_canceled
      not_canceled_invoice_items.should include(@not_canceled_invoice_item)
      not_canceled_invoice_items.should_not include(@canceled_invoice_item)
    end
    
    specify do
      canceled_invoice_items = InvoiceItem.canceled
      canceled_invoice_items.should include(@canceled_invoice_item)
      canceled_invoice_items.should_not include(@not_canceled_invoice_item)
    end
  end
  
  describe "validates" do
    subject { Factory(:invoice_item) }
    
    [:site_id, :item_type, :item_id, :started_on, :ended_on, :price, :overage_amount, :overage_price, :refund, :refunded_invoice_item_id].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:site) }
    it { should validate_presence_of(:invoice) }
    it { should validate_presence_of(:item_type) }
    it { should validate_presence_of(:item_id) }
    # it { should validate_presence_of(:started_on) }
    # it { should validate_presence_of(:ended_on) }
    it { should validate_presence_of(:price) }
    
    it { should validate_numericality_of(:price) }
    it { should validate_numericality_of(:overage_amount) }
    it { should validate_numericality_of(:overage_price) }
    it { should validate_numericality_of(:refund) }
  end
  
end

# == Schema Information
#
# Table name: invoice_items
#
#  id                       :integer         not null, primary key
#  site_id                  :integer
#  invoice_id               :integer
#  item_type                :string(255)
#  item_id                  :integer
#  started_on               :date
#  ended_on                 :date
#  canceled_at              :datetime
#  price                    :integer
#  overage_amount           :integer         default(0)
#  overage_price            :integer
#  refund                   :integer         default(0)
#  refunded_invoice_item_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#  index_invoice_items_on_site_id                (site_id)
#

