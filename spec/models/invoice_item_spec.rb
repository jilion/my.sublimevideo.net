require 'spec_helper'

describe InvoiceItem do
  
  context "with valid attributes" do
    set(:invoice_item) { Factory(:invoice_item) }
    
    subject { invoice_item }
    
    its(:site)                     { should be_present }
    its(:invoice)                  { should be_present }
    its(:item_type)                { should == 'Plan' }
    its(:item_id)                  { should be_present }
    its(:started_on)               { should == Date.new(2010,1,1) }
    its(:ended_on)                 { should == Date.new(2010,1,31) }
    its(:canceled_at)              { should be_nil }
    its(:price)                    { should == 100 }
    its(:overage_amount)           { should == 0 }
    its(:overage_price)            { should be_nil }
    its(:refund)                   { should == 0 }
    its(:refunded_invoice_item_id) { should be_nil }
    
    it { be_valid }
  end
  
  describe "validates" do
    it { should belong_to :site }
    it { should belong_to :invoice }
    
    # [:hostname, :dev_hostnames].each do |attr|
    #   it { should allow_mass_assignment_of(attr) }
    # end
    
    it { should validate_presence_of(:site) }
    it { should validate_presence_of(:invoice) }
    it { should validate_presence_of(:item_type) }
    it { should validate_presence_of(:item_id) }
    it { should validate_presence_of(:started_on) }
    it { should validate_presence_of(:ended_on) }
    it { should validate_presence_of(:price) }
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
#  price                    :integer
#  overage_amount           :integer
#  overage_price            :integer
#  started_on               :date
#  ended_on                 :date
#  canceled_at              :datetime
#  refund                   :integer
#  refunded_invoice_item_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#

