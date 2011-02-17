require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".build(attributes = {})" do
    before(:all) do
      @user    = Factory(:user)
      @plan    = Factory(:plan, :price => 1000)
      @site    = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15))
      @invoice = Factory(:invoice, :user => @user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month)
    end

    describe "shared logic" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15)) }
      subject { InvoiceItem::Plan.build(:site => @site, :invoice => @invoice) }

      specify { @site.activated_at.to_i.should == Time.utc(2010,1,15).to_i }
      specify { @site.archived_at.to_i.should == 0 }

      its(:item)  { should == @site.plan }
      its(:price) { should == @site.plan.price }
    end

    context "with a site activated before this month and not archived" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15)) }
      subject { InvoiceItem::Plan.build(:site => @site, :invoice => @invoice) }

      its(:minutes)    { should == 28 * 24 * 60 }
      its(:percentage) { should == (28 / 28.0).round(4) }
      its(:amount)     { should == (1000 * (28 / 28.0).round(4)).round }
      specify          { subject.started_at.to_i.should == subject.invoice.started_at.to_i }
      specify          { subject.ended_at.to_i.should == subject.invoice.ended_at.to_i }
    end

    context "with a site activated before this month and archived" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15), :archived_at => Time.utc(2010,2,15)) }
      subject { InvoiceItem::Plan.build(:site => @site, :invoice => @invoice) }

      its(:minutes)    { should == 14 * 24 * 60 }
      its(:percentage) { should == (14 / 28.0).round(4) }
      its(:amount)     { should == (1000 * (14 / 28.0).round(4)).round }
      specify          { subject.started_at.to_i.should == subject.invoice.started_at.to_i }
      specify          { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
    end

    context "with a site activated during the month and not archived" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,20)) }
      subject { InvoiceItem::Plan.build(:site => @site, :invoice => @invoice) }

      its(:minutes)    { should == 9 * 24 * 60 }
      its(:percentage) { should == (9 / 28.0).round(4) }
      its(:amount)     { should == (1000 * (9 / 28.0).round(4)).round }
      specify          { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      specify          { subject.ended_at.to_i.should == subject.invoice.ended_at.to_i }
    end

    context "with a site activated and archived during the month" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,15), :archived_at => Time.utc(2010,2,20)) }
      subject { InvoiceItem::Plan.build(:site => @site, :invoice => @invoice) }

      its(:minutes)    { should == 5 * 24 * 60 }
      its(:percentage) { should == (5 / 28.0).round(4) }
      its(:amount)     { should == (1000 * (5 / 28.0).round(4)).round }
      specify          { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      specify          { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
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

