require 'spec_helper'

describe InvoiceItem::Plan do
  
  # TODO, create a scenario where X & o are at the same date
  
  # 1/1   1/15  2/1   2/15  3/1   3/15  4/1 => date
  #  ^     ^     ^     ^     ^     ^     ^
  #  |--o--X--o--|--o--X'-o--|-----X-----|
  #     1     2     3     4                 => scenario
  #           2'    3'    4'                => scenario' (site cancelled before date)
  #           2"    3"    4"                => scenario" (plan upgraded/downgraded before date <=> current plan invoice_item canceled and new invoice_item created)
  # 
  # Legend :
  #   | is for site billing cycle
  #   X is for user billing cycle
  #   X' is for invoice that is not charged (because of a too small amount for example)
  #   o is for the date when we call InvoiceItem::Plan.open_invoice_items
  describe ".open_invoice_items" do
    after(:each) { Timecop.return }
    
    context "(scenario 1) with site just activated" do
      set(:site_scenario1) { Factory(:active_site) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario1) }
      
      specify { open_invoice_items.should have(1).invoice_item }
      
      describe "the only invoice_item" do
        subject { open_invoice_items.first }
        
        its(:site)        { should == site_scenario1 }
        its(:item)        { should == site_scenario1.plan }
        its(:invoice)     { should == site_scenario1.user.open_invoice }
        its(:price)       { should == site_scenario1.plan.price }
        its(:amount)      { should == site_scenario1.plan.price }
        its(:started_on)  { should == site_scenario1.billable_on }
        its(:ended_on)    { should == site_scenario1.billable_on + 1.send(site_scenario1.plan.term_type) }
        
        it { should be_new_record }
      end
    end
    
    context "(scenario 2) with current plan for site cycle already paid" do
      set(:user_scenario2) { Factory(:user, :billable_on => Time.utc_time(2010,2,15)) }
      set(:site_scenario2) { Factory(:active_site, :user => user_scenario2, :billable_on => Time.utc_time(2010,2,1)) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario2) }
      before(:each) { Timecop.travel(Time.utc_time(2010,1,20)) }
      
      specify { user_scenario2.billable_on.should == Time.utc_time(2010,2,15).to_date }
      specify { site_scenario2.billable_on.should == Time.utc_time(2010,2,1).to_date }
      specify { open_invoice_items.should have(1).invoice_item }
      
      describe "should return a new record for the next site cycle" do
        subject { open_invoice_items.first }
        
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
    
    context "(scenario 2') with current plan for site cycle already paid and canceled" do
      set(:user_scenario2p) { Factory(:user, :billable_on => Time.utc_time(2010,2,15)) }
      set(:site_scenario2p) { Factory(:active_site, :user => user_scenario2p, :billable_on => Time.utc_time(2010,2,1)) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario2p) }
      before(:each) do
        Timecop.travel(Time.utc_time(2010,1,19))
        site_scenario2p.archive
        Timecop.travel(Time.utc_time(2010,1,20))
      end
      
      specify { user_scenario2p.billable_on.should == Time.utc_time(2010,2,15).to_date }
      specify { site_scenario2p.billable_on.should == Time.utc_time(2010,2,1).to_date }
      specify { open_invoice_items.should have(0).invoice_item }
    end
    
    context "(scenario 2'') with current plan for site cycle already paid and upgraded" do
      set(:user_scenario2s) { Factory(:user, :billable_on => Time.utc_time(2010,2,15)) }
      set(:site_scenario2s) { Factory(:active_site, :user => user_scenario2s, :billable_on => Time.utc_time(2010,2,1)) }
      set(:old_invoice_item_scenario2s) { Factory(:plan_invoice_item, :site => site_scenario2s, :started_on => Time.utc_time(2010,1,1), :ended_on => Time.utc_time(2010,2,1), :canceled_at => Time.utc_time(2010,1,19)) }
      set(:new_invoice_item_scenario2s) { Factory(:plan_invoice_item, :site => site_scenario2s, :started_on => Time.utc_time(2010,1,1), :ended_on => Time.utc_time(2010,2,1)) }
      set(:new_plan_scenario2s) { Factory(:plan) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario2s) }
      before(:each) do
        Timecop.travel(Time.utc_time(2010,1,19))
        site_scenario2s.update_attribute(:plan_id, new_plan_scenario2s.id)
        Timecop.travel(Time.utc_time(2010,1,20))
      end
      
      specify { user_scenario2s.billable_on.should == Time.utc_time(2010,2,15).to_date }
      specify { site_scenario2s.billable_on.should == Time.utc_time(2010,2,1).to_date }
      specify { old_invoice_item_scenario2s.canceled_at.should == Time.utc_time(2010,1,19) }
      specify { open_invoice_items.should have(3).invoice_items } # implement upgrade/downgrade
      
      describe "should return a persisted and canceled record of the old plan for the current site cycle" do
        subject { open_invoice_items.first }
        
        it { should == old_invoice_item_scenario2s }
        it { should be_persisted }
      end
      
      describe "should return a persisted record of the new plan for the current site cycle" do
        subject { open_invoice_items.second }
        
        it { should == new_invoice_item_scenario2s }
        it { subject.site.plan.should == new_plan_scenario2s }
        it { should be_persisted }
      end
      
      describe "should return a new record for the next site cycle" do
        subject { open_invoice_items.last }
        
        its(:site)        { should == site_scenario2s }
        its(:item)        { should == site_scenario2s.plan }
        its(:invoice)     { should == site_scenario2s.user.open_invoice }
        its(:price)       { should == site_scenario2s.plan.price }
        its(:amount)      { should == site_scenario2s.plan.price }
        its(:started_on)  { should == site_scenario2s.billable_on }
        its(:ended_on)    { should == site_scenario2s.billable_on + 1.send(site_scenario2s.plan.term_type) }
        
        it { should be_new_record }
      end
    end
    
    context "(scenario 3) with current plan for site cycle not paid yet" do
      set(:user_scenario3) { Factory(:user, :billable_on => Time.utc_time(2010,2,15)) }
      set(:site_scenario3) { Factory(:active_site, :user => user_scenario3, :billable_on => Time.utc_time(2010,3,1)) }
      set(:invoice_item_scenario3) { Factory(:plan_invoice_item, :site => site_scenario3, :started_on => Time.utc_time(2010,2,1), :ended_on => Time.utc_time(2010,3,1)) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario3) }
      before(:each) { Timecop.travel(Time.utc_time(2010,2,7)) }
      
      specify { user_scenario3.billable_on.should == Time.utc_time(2010,2,15).to_date }
      specify { site_scenario3.billable_on.should == Time.utc_time(2010,3,1).to_date }
      specify { open_invoice_items.should have(1).invoice_item }
      
      describe "should return a persisted record for the current site cycle" do
        subject { open_invoice_items.first }
        
        it { should == invoice_item_scenario3 }
        it { should be_persisted }
      end
    end
    
    context "(scenario 3') with current plan for site cycle not paid yet and canceled" do
      set(:user_scenario3p) { Factory(:user, :billable_on => Time.utc_time(2010,2,15)) }
      set(:site_scenario3p) { Factory(:active_site, :user => user_scenario3p, :billable_on => Time.utc_time(2010,3,1)) }
      set(:invoice_item_scenario3p) { Factory(:plan_invoice_item, :site => site_scenario3p, :started_on => Time.utc_time(2010,2,1), :ended_on => Time.utc_time(2010,3,1), :canceled_at => Time.utc_time(2010,2,6)) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario3p) }
      before(:each) do
        Timecop.travel(Time.utc_time(2010,2,6))
        site_scenario3p.archive
        Timecop.travel(Time.utc_time(2010,2,7))
      end
      
      specify { user_scenario3p.billable_on.should == Time.utc_time(2010,2,15).to_date }
      specify { site_scenario3p.billable_on.should == Time.utc_time(2010,3,1).to_date }
      specify { invoice_item_scenario3p.canceled_at.should == Time.utc_time(2010,2,6) }
      specify { open_invoice_items.should have(1).invoice_item }
      
      describe "should return a persisted and canceled record for the current site cycle" do
        subject { open_invoice_items.first }
        
        it { should == invoice_item_scenario3p }
        it { should be_persisted }
      end
    end
    
    context "(scenario 3'') with current plan for site cycle not paid yet and upgraded" do
      set(:user_scenario3s) { Factory(:user, :billable_on => Time.utc_time(2010,2,15)) }
      set(:site_scenario3s) { Factory(:active_site, :user => user_scenario3s, :billable_on => Time.utc_time(2010,3,1)) }
      set(:old_invoice_item_scenario3s) { Factory(:plan_invoice_item, :site => site_scenario3s, :started_on => Time.utc_time(2010,2,1), :ended_on => Time.utc_time(2010,3,1), :canceled_at => Time.utc_time(2010,2,6)) }
      set(:new_invoice_item_scenario3s) { Factory(:plan_invoice_item, :site => site_scenario3s, :started_on => Time.utc_time(2010,2,1), :ended_on => Time.utc_time(2010,3,1)) }
      set(:new_plan_scenario3s) { Factory(:plan) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario3s) }
      before(:each) do
        Timecop.travel(Time.utc_time(2010,2,6))
        site_scenario3s.update_attribute(:plan_id, new_plan_scenario3s.id)
        Timecop.travel(Time.utc_time(2010,2,7))
      end
      
      specify { user_scenario3s.billable_on.should == Time.utc_time(2010,2,15).to_date }
      specify { site_scenario3s.billable_on.should == Time.utc_time(2010,3,1).to_date }
      specify { old_invoice_item_scenario3s.canceled_at.should == Time.utc_time(2010,2,6) }
      specify { open_invoice_items.should have(2).invoice_items }
      
      describe "should return a persisted and canceled record of the old plan for the current site cycle" do
        subject { open_invoice_items.first }
        
        it { should == old_invoice_item_scenario3s }
        it { should be_persisted }
      end
      
      describe "should return a persisted record of the new plan for the current site cycle" do
        subject { open_invoice_items.last }
        
        it { should == new_invoice_item_scenario3s }
        it { subject.site.plan.should == new_plan_scenario3s }
        it { should be_persisted }
      end
    end
    
    context "(scenario 4) with current plan for site cycle not paid yet and the open invoice not completed on last user.billable_on (still open), because of a too small amount" do
      set(:user_scenario4) { Factory(:user, :billable_on => Time.utc_time(2010,3,15)) }
      set(:site_scenario4) { Factory(:active_site, :user => user_scenario4, :billable_on => Time.utc_time(2010,3,1)) }
      set(:invoice_item_scenario4) { Factory(:plan_invoice_item, :site => site_scenario4, :started_on => Time.utc_time(2010,2,1), :ended_on => Time.utc_time(2010,3,1)) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario4) }
      before(:each) { Timecop.travel(Time.utc_time(2010,2,20)) }
      
      specify { user_scenario4.billable_on.should == Time.utc_time(2010,3,15).to_date }
      specify { site_scenario4.billable_on.should == Time.utc_time(2010,3,1).to_date }
      specify { open_invoice_items.should have(2).invoice_items }
      
      describe "first open_invoice_item, should be the still open_invoice_item from last user.billable_on" do
        subject { open_invoice_items.first }
        
        it { should == invoice_item_scenario4 }
        it { should be_persisted }
      end
      
      describe "last open_invoice_item, should return a new record for the next site cycle" do
        subject { open_invoice_items.last }
        
        it { should_not == invoice_item_scenario4 }
        
        its(:site)        { should == site_scenario4 }
        its(:item)        { should == site_scenario4.plan }
        its(:invoice)     { should == site_scenario4.user.open_invoice }
        its(:price)       { should == site_scenario4.plan.price }
        its(:amount)      { should == site_scenario4.plan.price }
        its(:started_on)  { should == site_scenario4.billable_on }
        its(:ended_on)    { should == site_scenario4.billable_on + 1.send(site_scenario4.plan.term_type) }
        
        it { should be_new_record }
      end
    end
    
    context "(scenario 4') with current plan for site cycle not paid yet and the open invoice not completed on last user.billable_on (still open), because of a too small amount and canceled" do
      set(:user_scenario4p) { Factory(:user, :billable_on => Time.utc_time(2010,3,15)) }
      set(:site_scenario4p) { Factory(:active_site, :user => user_scenario4p, :billable_on => Time.utc_time(2010,3,1)) }
      set(:invoice_item_scenario4p) { Factory(:plan_invoice_item, :site => site_scenario4p, :started_on => Time.utc_time(2010,2,1).utc, :ended_on => Time.utc_time(2010,3,1), :canceled_at => Time.utc_time(2010,2,19)) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario4p) }
      before(:each) do
        Timecop.travel(Time.utc_time(2010,2,19))
        site_scenario4p.archive
        Timecop.travel(Time.utc_time(2010,2,20))
      end
      
      specify { user_scenario4p.billable_on.should == Time.utc_time(2010,3,15).to_date }
      specify { site_scenario4p.billable_on.should == Time.utc_time(2010,3,1).to_date }
      specify { invoice_item_scenario4p.canceled_at.should == Time.utc_time(2010,2,19) }
      specify { open_invoice_items.should have(1).invoice_item }
      
      describe "the only open_invoice_item should be the still open_invoice_item from last user.billable_on" do
        subject { open_invoice_items.first }
        
        it { should == invoice_item_scenario4p }
        it { should be_persisted }
      end
    end
    
    context "(scenario 4'') with current plan for site cycle not paid yet and the open invoice not completed on last user.billable_on (still open), because of a too small amount and upgraded" do
      set(:user_scenario4s) { Factory(:user, :billable_on => Time.utc_time(2010,3,15)) }
      set(:site_scenario4s) { Factory(:active_site, :user => user_scenario4s, :billable_on => Time.utc_time(2010,3,1)) }
      set(:old_invoice_item_scenario4s) { Factory(:plan_invoice_item, :site => site_scenario4s, :started_on => Time.utc_time(2010,2,1), :ended_on => Time.utc_time(2010,3,1), :canceled_at => Time.utc_time(2010,2,19)) }
      set(:new_invoice_item_scenario4s) { Factory(:plan_invoice_item, :site => site_scenario4s, :started_on => Time.utc_time(2010,2,1), :ended_on => Time.utc_time(2010,3,1)) }
      set(:new_plan_scenario4s) { Factory(:plan) }
      let(:open_invoice_items) { InvoiceItem::Plan.open_invoice_items(site_scenario4s) }
      before(:each) do
        Timecop.travel(Time.utc_time(2010,2,19))
        site_scenario4s.update_attribute(:plan_id, new_plan_scenario4s.id)
        Timecop.travel(Time.utc_time(2010,2,20))
      end
      
      specify { user_scenario4s.billable_on.should == Time.utc_time(2010,3,15).to_date }
      specify { site_scenario4s.billable_on.should == Time.utc_time(2010,3,1).to_date }
      specify { old_invoice_item_scenario4s.canceled_at.should == Time.utc_time(2010,2,19) }
      specify { open_invoice_items.should have(3).invoice_items }
      
      describe "should return a persisted and canceled record of the old plan for the current site cycle" do
        subject { open_invoice_items.first }
        
        it { should == old_invoice_item_scenario4s }
        it { should be_persisted }
      end
      
      describe "should return a persisted record of the new plan for the current site cycle" do
        subject { open_invoice_items.second }
        
        it { should == new_invoice_item_scenario4s }
        it { subject.site.plan.should == new_plan_scenario4s }
        it { should be_persisted }
      end
      
      describe "should return a new record for the next site cycle" do
        subject { open_invoice_items.last }
        
        its(:site)        { should == site_scenario4s }
        its(:item)        { should == site_scenario4s.plan }
        its(:invoice)     { should == site_scenario4s.user.open_invoice }
        its(:price)       { should == site_scenario4s.plan.price }
        its(:amount)      { should == site_scenario4s.plan.price }
        its(:started_on)  { should == site_scenario4s.billable_on }
        its(:ended_on)    { should == site_scenario4s.billable_on + 1.send(site_scenario4s.plan.term_type) }
        
        it { should be_new_record }
      end
    end
    
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

