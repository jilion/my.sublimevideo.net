require 'spec_helper'

describe InvoiceItem do
  
  context "Factory" do
    before(:all) { @invoice_item = Factory(:plan_invoice_item) }
    subject { @invoice_item }
    
    its(:site)      { should be_present }
    its(:invoice)   { should be_present }
    its(:user)      { should == @invoice_item.site.user }
    its(:type)      { should == 'InvoiceItem::Plan' }
    its(:item_type) { should == 'Plan' }
    its(:item_id)   { should be_present }
    specify { subject.started_at.to_i.should == Time.now.utc.beginning_of_month.to_i }
    specify { subject.ended_at.to_i.should == Time.now.utc.end_of_month.to_i }
    its(:price)     { should == 1000 }
    its(:amount)    { should == 1000 }
    
    it { should be_valid }
  end # Factory
  
  describe "Associations" do
    before(:all) { @invoice_item = Factory(:plan_invoice_item) }
    subject { @invoice_item }
    
    it { should belong_to :site }
    it { should belong_to :invoice }
    it { should belong_to :item }
  end # Associations
  
  describe "Validations" do
    [:site, :invoice, :info].each do |attr|
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
  end # Validations
  
  describe "#minutes" do
    specify { build_invoice_item(Time.utc(2010,1).beginning_of_month, Time.utc(2010,1).end_of_month).minutes.should == 31*24*60 }
    specify { build_invoice_item(Time.utc(2010,1,1,0,0,0), Time.utc(2010,1,1,0,0,0)).minutes.should == 0 }
    specify { build_invoice_item(Time.utc(2010,1,1,0,0,0), Time.utc(2010,1,1,0,0,1)).minutes.should == 1 }
  end
  
  describe "#percentage" do
    context "with a full month invoice and a one week invoice item" do
      before(:all) do
        @invoice      = Factory(:invoice, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month)
        @invoice_item = Factory(:plan_invoice_item, :invoice => @invoice, :started_at => Time.utc(2010,2,10), :ended_at => Time.utc(2010,2,17))
      end
      subject { @invoice_item }
      
      its(:percentage) { should == 7 / 28.0 }
    end
    
    context "with a two weeks invoice and a two days invoice item" do
      before(:all) do
        @invoice      = Factory(:invoice, :started_at => Time.utc(2010,2.1), :ended_at => Time.utc(2010,2,14).end_of_day)
        @invoice_item = Factory(:plan_invoice_item, :invoice => @invoice, :started_at => Time.utc(2010,2,2), :ended_at => Time.utc(2010,2,3).end_of_day)
      end
      subject { @invoice_item }
      
      its(:percentage) { should == (2 / 28.0).round(4) }
    end
    
  end
  
end

def build_invoice_item(started_at, ended_at)
  Factory.build(:plan_invoice_item, :started_at => started_at, :ended_at => ended_at)
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

