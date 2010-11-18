require 'spec_helper'

describe InvoiceItem::Plan do
  
  # 1/1   1/15  2/1   2/15  3/1   3/15  4/1 => date
  #  ^     ^     ^     ^     ^     ^     ^
  #  |--o--X--o--|--o--X'-o--|-----X-----|
  #     1     2     3     4                  => scenario
  #           2'    3'    4'                 => scenario' (site cancelled before date)
  # 
  # Legend :
  #   | is for site billing cycle
  #   X is for user billing cycle
  #   X' is for invoice that is not charged (because of a too small amount for example)
  #   o is for the date when we call InvoiceItem::Plan.open_invoice_item
  describe ".open_invoice_item" do
    after(:each) { Timecop.return }
    
    context "(scenario 1) with site just activated" do
      set(:site_just_activated) { Factory(:active_site) }
      subject { InvoiceItem::Plan.open_invoice_item(site_just_activated) }
      
      its(:site)        { should == site_just_activated }
      its(:item)        { should == site_just_activated.plan }
      its(:invoice)     { should == site_just_activated.user.open_invoice }
      its(:price)       { should == site_just_activated.plan.price }
      its(:amount)      { should == site_just_activated.plan.price }
      its(:started_on)  { should == site_just_activated.billable_on }
      its(:ended_on)    { should == site_just_activated.billable_on + 1.send(site_just_activated.plan.term_type) }
      
      it { should be_new_record }
    end
    
    context "(scenario 2) with current plan for site cycle already paid" do
      set(:user_scenario2) { Factory(:user, :billable_on => Time.new(2010,2,15).utc.to_date) }
      set(:site_scenario2) { Factory(:active_site, :user => user_scenario2, :billable_on => Time.new(2010,2,1).utc.to_date) }
      before(:each) { Timecop.travel(Time.new(2010,1,20).utc) }
      
      describe "should return a new record for the next site cycle" do
        subject { InvoiceItem::Plan.open_invoice_item(site_scenario2) }
        
        its(:site)        { should == site_scenario2 }
        its(:item)        { should == site_scenario2.plan }
        its(:invoice)     { should == site_scenario2.user.open_invoice }
        its(:price)       { should == site_scenario2.plan.price }
        its(:amount)      { should == site_scenario2.plan.price }
        its(:started_on)  { should == site_scenario2.billable_on }
        its(:ended_on)    { should == site_scenario2.billable_on + 1.send(site_scenario2.plan.term_type) }
        
        it { should be_new_record }
      end
    end
    
    context "(scenario 2') with current plan for site cycle already paid and cancelled" do
      set(:user_scenario2p) { Factory(:user, :billable_on => Time.new(2010,2,15).utc.to_date) }
      set(:site_scenario2p) { Factory(:active_site, :user => user_scenario2p, :billable_on => Time.new(2010,2,1).utc.to_date) }
      before(:each) do
        Timecop.travel(Time.new(2010,1,19).utc)
        site_scenario2p.archive
        Timecop.travel(Time.new(2010,1,20).utc)
      end
      
      describe "should return a new record for the next site cycle" do
        subject { InvoiceItem::Plan.open_invoice_item(site_scenario2p) }
        
        it { should be_nil }
      end
    end
    
    context "(scenario 3) with current plan for site cycle not paid yet" do
      set(:user_scenario3) { Factory(:user, :billable_on => Time.new(2010,2,15).utc.to_date) }
      set(:site_scenario3) { Factory(:active_site, :user => user_scenario3, :billable_on => Time.new(2010,3,1).utc.to_date) }
      set(:invoice_item_scenario3) { Factory(:plan_invoice_item, :site => site_scenario3, :started_on => Time.new(2010,2,1).utc.to_date, :ended_on => Time.new(2010,3,1).utc.to_date) }
      before(:each) { Timecop.travel(Time.new(2010,2,7).utc) }
      
      describe "should return a persisted record for the current site cycle" do
        subject { InvoiceItem::Plan.open_invoice_item(site_scenario3) }
        
        it { should == invoice_item_scenario3 }
        it { should be_persisted }
      end
    end
    
    context "(scenario 3) with current plan for site cycle not paid yet and cancelled" do
      set(:user_scenario3p) { Factory(:user, :billable_on => Time.new(2010,2,15).utc.to_date) }
      set(:site_scenario3p) { Factory(:active_site, :user => user_scenario3p, :billable_on => Time.new(2010,3,1).utc.to_date) }
      let(:invoice_item_scenario3p) { Factory(:plan_invoice_item, :site => site_scenario3p, :started_on => Time.new(2010,2,1).utc.to_date, :ended_on => Time.new(2010,3,1).utc.to_date, :canceled_at => Time.new(2010,2,6).utc) }
      before(:each) do
        Timecop.travel(Time.new(2010,2,6).utc)
        site_scenario3p.archive
        Timecop.travel(Time.new(2010,2,7).utc)
      end
      
      describe "should return a persisted record for the current site cycle" do
        subject { InvoiceItem::Plan.open_invoice_item(site_scenario3p) }
        
        it { should == invoice_item_scenario3p }
        it { should be_persisted }
      end
    end
    
    context "(scenario 4) with current plan for site cycle not paid yet and last invoice not completed (still open), because of a too small amount" do
      before(:each) do
        @user = Factory(:user, :billable_on => Time.new(2010,3,15).utc.to_date)
        @site = Factory(:active_site, :user => @user, :billable_on => Time.new(2010,3,1).utc.to_date)
        @invoice_item = Factory(:plan_invoice_item, :site => @site, :started_on => Time.new(2010,2,1).utc.to_date, :ended_on => Time.new(2010,3,1).utc.to_date)
        Timecop.travel(Time.new(2010,2,20).utc)
      end
      subject { InvoiceItem::Plan.open_invoice_item(@site) }
      
      it "should return a new record for the next site cycle" do
        subject.should_not == @invoice_item
        subject.site.should == @site
        subject.item.should == @site.plan
        subject.invoice.should == @site.user.open_invoice
        subject.price.should == @site.plan.price
        subject.amount.should == @site.plan.price
        subject.started_on.should == @site.billable_on
        subject.ended_on.should == @site.billable_on + 1.send(@site.plan.term_type)
        subject.should be_new_record
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

