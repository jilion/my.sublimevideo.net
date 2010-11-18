require 'spec_helper'

describe InvoiceItem::Plan do
  
  describe ".open_invoice_item" do
    
    context "with site just activated" do
      set(:site) { Factory(:active_site) }
      subject { InvoiceItem::Plan.open_invoice_item(site) }
      
      its(:site)        { should == site }
      its(:item)        { should == site.plan }
      its(:invoice)     { should == site.user.open_invoice }
      its(:price)       { should == site.plan.price }
      its(:amount)      { should == site.plan.price }
      its(:started_on)  { should == site.billable_on }
      its(:ended_on)    { should == site.billable_on + 1.send(site.plan.term_type) }
      
      it { should be_new_record }
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

