require 'spec_helper'

describe InvoiceItem::Refund do
  
  # 1/1   1/15  2/1   2/15  3/1   3/15  4/1 => date
  #  ^     ^     ^     ^     ^     ^     ^
  #  |--o--X--o--|--o--X'-o--|-----X-----|
  #     1                                   => scenario
  # 
  # Legend :
  #   | is for site billing cycle
  #   X is for user billing cycle
  #   X' is for invoice that is not charged (because of a too small amount for example)
  #   o is for the date when we call InvoiceItem::Plan.open_invoice_items
  describe ".open_invoice_items" do
    after(:each) { Timecop.return }
    
    context "(scenario 1) with plan upgraded" do
      set(:user) { Factory(:user, :billable_on => Time.new(2010,1,15).utc.to_date) }
      set(:site) { Factory(:active_site, :user => user, :billable_on => Time.new(2010,2,1).utc.to_date) }
      set(:plan_invoice_item) { Factory(:plan_invoice_item, :site => site, :started_on => Time.new(2010,1,1).utc.to_date, :ended_on => Time.new(2010,2,1).utc.to_date, :canceled_at => Time.new(2010,1,9).utc) }
      set(:invoice_item) { Factory(:refund_invoice_item, :site => site, :item => plan_invoice_item, :started_on => Time.new(2010,1,1).utc, :ended_on => Time.new(2010,2,1).utc) }
      let(:open_invoice_items) { InvoiceItem::Refund.open_invoice_items(site) }
      before(:each) do
        Timecop.travel(Time.new(2010,1,10).utc)
      end
      
      specify { user.billable_on.should == Time.new(2010,1,15).utc.to_date }
      specify { site.billable_on.should == Time.new(2010,2,1).utc.to_date }
      specify { open_invoice_items.should have(1).invoice_item }
      
      describe "should return a persisted item" do
        subject { open_invoice_items.first }
        
        it { should == invoice_item }
        it { should be_persisted }
      end
    end
  
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

