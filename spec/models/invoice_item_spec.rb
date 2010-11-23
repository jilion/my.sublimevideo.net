require 'spec_helper'

describe InvoiceItem do
  set(:invoice_item) { Factory(:plan_invoice_item) }
  
  context "from factory" do
    subject { invoice_item }
    
    its(:site)        { should be_present }
    its(:invoice)     { should be_present }
    its(:user)        { should == invoice_item.site.user }
    its(:type)        { should == 'InvoiceItem::Plan' }
    its(:item_type)   { should == 'Plan' }
    its(:item_id)     { should be_present }
    specify { subject.started_at.to_i.should == Time.now.utc.beginning_of_month.to_i }
    specify { subject.ended_at.to_i.should == Time.now.utc.end_of_month.to_i }
    its(:price)       { should == 50 }
    its(:amount)      { should == 50 }
    
    it { should be_valid }
  end
  
  describe "associations" do
    subject { invoice_item }
    
    it { should belong_to :site }
    it { should belong_to :invoice }
    it { should belong_to :item }
  end
  
  describe "validates" do
    [:site, :invoice, :item, :price, :amount, :started_at, :ended_at, :info].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:site) }
    it { should validate_presence_of(:invoice) }
    it { should validate_presence_of(:item_type) }
    it { should validate_presence_of(:item_id) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }
    
    it { should validate_numericality_of(:price) }
    it { should validate_numericality_of(:amount) }
  end
  
end


# == Schema Information
#
# Table name: invoice_items
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  site_id    :integer
#  invoice_id :integer
#  item_type  :string(255)
#  item_id    :integer
#  started_at :datetime
#  ended_at   :datetime
#  price      :integer
#  amount     :integer
#  info       :text
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#  index_invoice_items_on_site_id                (site_id)
#

