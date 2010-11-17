require 'spec_helper'

describe InvoiceItem do
  context "from factory" do
    set(:invoice_item_from_factory) { Factory(:plan_invoice_item) }
    subject { invoice_item_from_factory }
    
    its(:site)                     { should == invoice_item_from_factory.site }
    its(:user)                     { should == invoice_item_from_factory.site.user }
    its(:invoice)                  { should == invoice_item_from_factory.site.user.open_invoice }
    its(:type)                     { should == 'InvoiceItem::Plan' }
    its(:item_type)                { should == 'Plan' }
    its(:item_id)                  { should be_present }
    its(:started_on)               { should == Time.now.utc.to_date }
    its(:ended_on)                 { should == 1.month.from_now.to_date }
    its(:canceled_at)              { should be_nil }
    its(:price)                    { should == 50 }
    its(:amount)                   { should == 50 }
    
    it { should be_valid }
  end
  
  describe "associations" do
    set(:invoice_item_for_associations) { Factory(:plan_invoice_item) }
    subject { invoice_item_for_associations }
    
    it { should belong_to :site }
    it { should belong_to :invoice }
    it { should belong_to :item }
  end
  
  describe "scopes" do
    before(:all) do
      Factory(:plan_invoice_item)
      @not_canceled_invoice_item = InvoiceItem::Plan.last
      Factory(:plan_invoice_item, :canceled_at => Time.now.utc)
      @canceled_invoice_item = InvoiceItem::Plan.last
    end
    
    specify do
      not_canceled_invoice_items = InvoiceItem::Plan.not_canceled
      not_canceled_invoice_items.should include(@not_canceled_invoice_item)
      not_canceled_invoice_items.should_not include(@canceled_invoice_item)
    end
    
    specify do
      canceled_invoice_items = InvoiceItem::Plan.canceled
      canceled_invoice_items.should include(@canceled_invoice_item)
      canceled_invoice_items.should_not include(@not_canceled_invoice_item)
    end
  end
  
  describe "validates" do
    subject { Factory(:plan_invoice_item) }
    
    [:site, :item, :price, :started_on, :ended_on, :info].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:site) }
    it { should validate_presence_of(:invoice) }
    it { should validate_presence_of(:item_type) }
    it { should validate_presence_of(:item_id) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:started_on) }
    it { should validate_presence_of(:ended_on) }
    
    it { should validate_numericality_of(:price) }
    it { should validate_numericality_of(:amount) }
  end
  
end



# == Schema Information
#
# Table name: invoice_items
#
#  id          :integer         not null, primary key
#  type        :string(255)
#  site_id     :integer
#  invoice_id  :integer
#  item_type   :string(255)
#  item_id     :integer
#  started_on  :date
#  ended_on    :date
#  canceled_at :datetime
#  price       :integer
#  amount      :integer
#  info        :text
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#  index_invoice_items_on_site_id                (site_id)
#

