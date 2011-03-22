require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".build(attributes = {})" do
    before(:all) do
      @user    = Factory(:user)
      @plan    = Factory(:plan, price: 1000)
      @site    = Factory(:site, user: @user, plan: @plan)
      @invoice = Factory(:invoice, site: @site)
    end

    describe "with standard params" do
      subject { InvoiceItem::Plan.build(invoice: @invoice, item: @site.plan) }

      its(:item)       { should == @site.plan }
      its(:price)      { should == @site.plan.price }
      its(:amount)     { should == @site.plan.price }
      its(:started_at) { should == @site.pending_plan_cycle_started_at }
      its(:ended_at)   { should == @site.pending_plan_cycle_ended_at }
    end

    describe "with refund params" do
      before(:all) { @plan2 = Factory(:plan, price: 1000) }
      subject { InvoiceItem::Plan.build(invoice: @invoice, item: @plan2, refund: true) }

      its(:item)       { should == @plan2 }
      its(:price)      { should == @plan2.price }
      its(:amount)     { should == -1 * @plan2.price }
      its(:started_at) { should == @site.plan_cycle_started_at }
      its(:ended_at)   { should == @site.plan_cycle_ended_at }
    end
  end

end



# == Schema Information
#
# Table name: invoice_items
#
#  id         :integer         not null, primary key
#  type       :string(255)
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
#

