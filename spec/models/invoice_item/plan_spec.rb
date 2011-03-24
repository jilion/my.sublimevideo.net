require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".build(attributes = {})" do
    before(:all) do
      @user    = Factory(:user)
      @plan1   = Factory(:plan, price: 1000)
      @plan2   = Factory(:plan, price: 1000)
      @site1   = Factory(:site, user: @user, plan_id: @plan1.id)
      @site2   = Factory(:site, user: @user, plan_id: @plan1.id)
      @site2.plan_id = @plan2.id
      @site2.save_without_password_validation
      @invoice1 = Factory(:invoice, site: @site1)
      @invoice2 = Factory(:invoice, site: @site2)
    end

    describe "with standard params and a site without pending plan" do # renew
      subject { InvoiceItem::Plan.build(invoice: @invoice1, item: @site1.plan) }

      its(:item)       { should == @site1.plan }
      its(:price)      { should == @site1.plan.price }
      its(:amount)     { should == @site1.plan.price }
      its(:started_at) { should == @site1.plan_cycle_started_at }
      its(:ended_at)   { should == @site1.plan_cycle_ended_at }
    end

    describe "with standard params and a site with pending plan" do # upgrade & downgrade
      subject { InvoiceItem::Plan.build(invoice: @invoice2, item: @site2.plan) }

      its(:item)       { should == @site2.plan }
      its(:price)      { should == @site2.plan.price }
      its(:amount)     { should == @site2.plan.price }
      its(:started_at) { should == @site2.pending_plan_cycle_started_at }
      its(:ended_at)   { should == @site2.pending_plan_cycle_ended_at }
    end

    describe "with refund params" do
      before(:all) { @plan3 = Factory(:plan, price: 1000) }
      subject { InvoiceItem::Plan.build(invoice: @invoice1, item: @plan3, refund: true) }

      its(:item)       { should == @plan3 }
      its(:price)      { should == @plan3.price }
      its(:amount)     { should == -1 * @plan3.price }
      its(:started_at) { should == @site1.plan_cycle_started_at }
      its(:ended_at)   { should == @site1.plan_cycle_ended_at }
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

