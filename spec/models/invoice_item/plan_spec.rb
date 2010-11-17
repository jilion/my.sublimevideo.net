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
