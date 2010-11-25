require 'spec_helper'

describe InvoiceItem::Addon do
  
  describe ".build(attributes = {})" do
    set(:user)    { Factory(:user) }
    set(:plan)    { Factory(:plan, :price => 1000) }
    set(:invoice) { Factory(:invoice, :user => user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month) }
    set(:addon)   { Factory(:addon, :price => 100) }
    
    describe "shared logic" do
      set(:site)     { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,1,15)) }
      set(:lifetime) { Factory(:lifetime, :site => site, :item => addon, :created_at => Time.utc(2010,1,1)) }
      subject { InvoiceItem::Addon.build(:site => site, :lifetime => lifetime, :invoice => invoice) }
      
      specify { site.activated_at.to_i.should == Time.utc(2010,1,15).to_i }
      specify { site.archived_at.to_i.should == 0 }
      specify { lifetime.created_at.to_i.should == Time.utc(2010,1,1).to_i }
      specify { lifetime.deleted_at.to_i.should == 0 }
      
      specify { lifetime.site.should == site }
      specify { lifetime.item.should == addon }
      
      its(:item)  { should == lifetime.item }
      its(:price) { should == lifetime.item.price }
    end
    
    describe "invoice_item.started_at set to invoice_item.invoice.started_at" do
      context "with an addon and its site activated before this month" do
        set(:site1)     { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,1,15)) }
        set(:lifetime1) { Factory(:lifetime, :site => site1, :item => addon, :created_at => Time.utc(2010,1,1)) }
        subject { InvoiceItem::Addon.build(:site => site1, :lifetime => lifetime1, :invoice => invoice) }
        
        its(:minutes)    { should == 28 * 24 * 60 }
        its(:percentage) { should == (28 / 28.0).round(2) }
        its(:amount)     { should == (100 * (28 / 28.0).round(2)).round }
        specify          { subject.started_at.to_i.should == subject.invoice.started_at.to_i }
      end
    end
    
    describe "invoice_item.started_at set to invoice_item.site.activated_at" do
      context "with an addon activated before this month and its site activated during this month" do
        set(:site2)     { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,20)) }
        set(:lifetime2) { Factory(:lifetime, :site => site2, :item => addon, :created_at => Time.utc(2010,1,1)) }
        subject { InvoiceItem::Addon.build(:site => site2, :lifetime => lifetime2, :invoice => invoice) }
        
        its(:minutes)    { should == 9 * 24 * 60 }
        its(:percentage) { should == (9 / 28.0).round(2) }
        its(:amount)     { should == (100 * (9 / 28.0).round(2)).round }
        specify          { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      end
    end
    
    describe "invoice_item.started_at set to invoice_item.lifetime.created_at" do
      context "with an addon activated during this month (after its site activation)" do
        set(:site3)     { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,1)) }
        set(:lifetime3) { Factory(:lifetime, :site => site3, :item => addon, :created_at => Time.utc(2010,2,20)) }
        subject { InvoiceItem::Addon.build(:site => site3, :lifetime => lifetime3, :invoice => invoice) }
        
        its(:minutes)    { should == 9 * 24 * 60 }
        its(:percentage) { should == (9 / 28.0).round(2) }
        its(:amount)     { should == (100 * (9 / 28.0).round(2)).round }
        specify          { subject.started_at.to_i.should == subject.lifetime.created_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.invoice.ended_at" do
      context "with an addon not deleted during this month" do
        set(:site4)     { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,1)) }
        set(:lifetime4) { Factory(:lifetime, :site => site4, :item => addon, :created_at => Time.utc(2010,2,20)) }
        subject { InvoiceItem::Addon.build(:site => site4, :lifetime => lifetime4, :invoice => invoice) }
        
        its(:minutes)    { should == 9 * 24 * 60 }
        its(:percentage) { should == (9 / 28.0).round(2) }
        its(:amount)     { should == (100 * (9 / 28.0).round(2)).round }
        specify          { subject.ended_at.to_i.should == subject.invoice.ended_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.site.archived_at" do
      context "with an addon's site archived during this month" do
        set(:site5)     { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,15), :archived_at => Time.utc(2010,2,20)) }
        set(:lifetime5) { Factory(:lifetime, :site => site5, :item => addon, :created_at => Time.utc(2010,2,1)) }
        subject { InvoiceItem::Addon.build(:site => site5, :lifetime => lifetime5, :invoice => invoice) }
        
        its(:minutes)    { should == 5 * 24 * 60 }
        its(:percentage) { should == (5 / 28.0).round(2) }
        its(:amount)     { should == (100 * (5 / 28.0).round(2)).round }
        specify          { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.lifetime.deleted_at" do
      context "with an addon deleted during this month" do
        set(:site6)     { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,15)) }
        set(:lifetime6) { Factory(:lifetime, :site => site6, :item => addon, :created_at => Time.utc(2010,2,15), :deleted_at => Time.utc(2010,2,20) ) }
        subject { InvoiceItem::Addon.build(:site => site6, :lifetime => lifetime6, :invoice => invoice) }
        
        its(:minutes)    { should == 5 * 24 * 60 }
        its(:percentage) { should == (5 / 28.0).round(2) }
        its(:amount)     { should == (100 * (5 / 28.0).round(2)).round }
        specify          { subject.ended_at.to_i.should == subject.lifetime.deleted_at.to_i }
      end
    end
    
  end
  
end