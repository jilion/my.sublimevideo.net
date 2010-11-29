require 'spec_helper'

describe InvoiceItem::Addon do
  
  describe ".build(attributes = {})" do
    before(:all) do
      @user    = Factory(:user)
      @plan    = Factory(:plan, :price => 1000)
      @invoice = Factory(:invoice, :user => @user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month)
      @addon   = Factory(:addon, :price => 100)
    end
    
    describe "shared logic" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,1,1))
      end
      subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
      
      specify { @site.activated_at.to_i.should == Time.utc(2010,1,15).to_i }
      specify { @site.archived_at.to_i.should == 0 }
      specify { @lifetime.created_at.to_i.should == Time.utc(2010,1,1).to_i }
      specify { @lifetime.deleted_at.to_i.should == 0 }
      
      specify { @lifetime.site.should == @site }
      specify { @lifetime.item.should == @addon }
      
      its(:item)  { should == @lifetime.item }
      its(:price) { should == @lifetime.item.price }
    end
    
    describe "invoice_item.started_at set to invoice_item.invoice.started_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,1,1))
      end
      context "with an addon and its site activated before this month" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 28 * 24 * 60 }
        its(:percentage) { should == (28 / 28.0).round(4) }
        its(:amount)     { should == (100 * (28 / 28.0).round(4)).round }
        specify          { subject.started_at.to_i.should == subject.invoice.started_at.to_i }
      end
    end
    
    describe "invoice_item.started_at set to invoice_item.site.activated_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,20))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,1,1))
      end
      context "with an addon activated before this month and its site activated during this month" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 9 * 24 * 60 }
        its(:percentage) { should == (9 / 28.0).round(4) }
        its(:amount)     { should == (100 * (9 / 28.0).round(4)).round }
        specify          { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      end
    end
    
    describe "invoice_item.started_at set to invoice_item.lifetime.created_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,1))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,2,20))
      end
      context "with an addon activated during this month (after its site activation)" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 9 * 24 * 60 }
        its(:percentage) { should == (9 / 28.0).round(4) }
        its(:amount)     { should == (100 * (9 / 28.0).round(4)).round }
        specify          { subject.started_at.to_i.should == subject.lifetime.created_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.invoice.ended_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,1))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,2,20))
      end
      context "with an addon not deleted during this month" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 9 * 24 * 60 }
        its(:percentage) { should == (9 / 28.0).round(4) }
        its(:amount)     { should == (100 * (9 / 28.0).round(4)).round }
        specify          { subject.ended_at.to_i.should == subject.invoice.ended_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.site.archived_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,15), :archived_at => Time.utc(2010,2,20))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,2,1))
      end
      context "with an addon's site archived during this month" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 5 * 24 * 60 }
        its(:percentage) { should == (5 / 28.0).round(4) }
        its(:amount)     { should == (100 * (5 / 28.0).round(4)).round }
        specify          { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.lifetime.deleted_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,15))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,2,15), :deleted_at => Time.utc(2010,2,20))
      end
      context "with an addon deleted during this month" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 5 * 24 * 60 }
        its(:percentage) { should == (5 / 28.0).round(4) }
        its(:amount)     { should == (100 * (5 / 28.0).round(4)).round }
        specify          { subject.ended_at.to_i.should == subject.lifetime.deleted_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.invoice.ended_at if invoice_item.lifetime.deleted_at > invoice_item.invoice.ended_at && invoice_item.site.archived_at > invoice_item.invoice.ended_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,15))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,2,15), :deleted_at => Time.utc(2010,3,20))
      end
      context "with an addon deleted during this month" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 14 * 24 * 60 }
        its(:percentage) { should == (14 / 28.0).round(4) }
        its(:amount)     { should == (100 * (14 / 28.0).round(4)).round }
        specify          { subject.ended_at.to_i.should == subject.invoice.ended_at.to_i }
      end
    end
    
    describe "invoice_item.ended_at set to invoice_item.site.archived_at if invoice_item.lifetime.deleted_at > invoice_item.invoice.ended_at && invoice_item.invoice.ended_at > invoice_item.site.archived_at" do
      before(:all) do
        @site     = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,15), :archived_at => Time.utc(2010,2,20))
        @lifetime = Factory(:lifetime, :site => @site, :item => @addon, :created_at => Time.utc(2010,2,1), :deleted_at => Time.utc(2010,3,20))
      end
      context "with an addon's site archived during this month" do
        subject { InvoiceItem::Addon.build(:site => @site, :lifetime => @lifetime, :invoice => @invoice) }
        
        its(:minutes)    { should == 5 * 24 * 60 }
        its(:percentage) { should == (5 / 28.0).round(4) }
        its(:amount)     { should == (100 * (5 / 28.0).round(4)).round }
        specify          { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
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

