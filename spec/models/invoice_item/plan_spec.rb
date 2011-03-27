require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".build(attributes = {})" do
    before(:all) do
      @user       = Factory(:user)
      @enthusiast = Factory(:user, enthusiast_id: 1234)

      @plan1 = Factory(:plan, price: 1000)
      @plan2 = Factory(:plan, price: 1000)

      @site1 = Factory(:site, user: @user, plan_id: @plan1.id)
      @site2 = Factory(:site, user: @user, plan_id: @plan1.id)
      @site2.plan_id = @plan2.id
      @site2.save_without_password_validation
      Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) { @site_with_discount = Factory(:site, user: @enthusiast, plan_id: @plan1.id) }

      @invoice1 = Factory(:invoice, site: @site1)
      @invoice2 = Factory(:invoice, site: @site2)
      @invoice_with_discount = Factory(:invoice, site: @site_with_discount)
    end

    context "with a site that doesn't have the discount" do
      # renew
      describe "with standard params and a site without pending plan" do
        subject { InvoiceItem::Plan.build(invoice: @invoice1, item: @site1.plan) }

        its(:item)       { should == @site1.plan }
        its(:price)      { should == @site1.plan.price }
        its(:amount)     { should == @site1.plan.price }
        its(:started_at) { should == @site1.plan_cycle_started_at }
        its(:ended_at)   { should == @site1.plan_cycle_ended_at }
      end

      # upgrade & downgrade
      describe "with standard params and a site with pending plan" do
        subject { InvoiceItem::Plan.build(invoice: @invoice2, item: @site2.plan) }

        its(:item)       { should == @site2.plan }
        its(:price)      { should == @site2.plan.price }
        its(:amount)     { should == @site2.plan.price }
        its(:started_at) { should == @site2.pending_plan_cycle_started_at }
        its(:ended_at)   { should == @site2.pending_plan_cycle_ended_at }
      end

      describe "with refund params" do
        subject { InvoiceItem::Plan.build(invoice: @invoice1, item: @plan1, refund: true) }

        its(:item)       { should == @plan1 }
        its(:price)      { should == @plan1.price }
        its(:amount)     { should == -1 * @plan1.price }
        its(:started_at) { should == @site1.plan_cycle_started_at }
        its(:ended_at)   { should == @site1.plan_cycle_ended_at }
      end
    end

    context "with a site that have the discount" do
      describe "no refund" do
        subject { InvoiceItem::Plan.build(invoice: @invoice_with_discount, item: @plan1) }

        its(:item)       { should == @plan1 }
        its(:price)      { should == 800 }
        its(:amount)     { should == 800 }
        its(:started_at) { should == @site_with_discount.plan_cycle_started_at }
        its(:ended_at)   { should == @site_with_discount.plan_cycle_ended_at }
      end

      describe "refund" do
        subject { InvoiceItem::Plan.build(invoice: @invoice_with_discount, item: @plan1, refund: true) }

        its(:item)       { should == @plan1 }
        its(:price)      { should == 800 }
        its(:amount)     { should == -800 }
        its(:started_at) { should == @site_with_discount.plan_cycle_started_at }
        its(:ended_at)   { should == @site_with_discount.plan_cycle_ended_at }
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
#  invoice_id :integer
#  item_type  :string(255)
#  item_id    :integer
#  started_at :datetime
#  ended_at   :datetime
#  price      :integer
#  amount     :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#

