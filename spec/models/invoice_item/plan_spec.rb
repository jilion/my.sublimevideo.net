require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".build(attributes={})" do
    before(:all) do
      @not_enthusiast = Factory(:user, invitation_token: "123asd", created_at: Time.utc(2010,10,10))
      @enthusiast     = Factory(:user, invitation_token: nil, created_at: Time.utc(2010,10,10))

      @plan1 = Factory(:plan, price: 1000)
      @plan2 = Factory(:plan, price: 2000)

      Timecop.travel(Time.utc(2011,5,1)) do
        @site1 = Factory.build(:new_site, user: @not_enthusiast, plan_id: @plan1.id)
        @site2 = Factory(:site_with_invoice, user: @not_enthusiast, plan_id: @plan1.id)
        @site2.plan_id = @plan2.id # upgrade
        @site2.pend_plan_changes # simulate upgrade
        @site3 = Factory(:site, user: @not_enthusiast, plan_id: @plan2.id)
        @site3.plan_id = @plan1.id # downgrade
      end

      Timecop.travel(Time.utc(2011,6,1)) do
        @site3.pend_plan_changes # simulate downgrade
      end

      @invoice1 = Factory(:invoice, site: @site1)
      @invoice2 = Factory(:invoice, site: @site2)
      @invoice3 = Factory(:invoice, site: @site3)
    end

    describe "new or renew" do
      describe "with standard params and a site without pending plan" do
        subject { InvoiceItem::Plan.build(invoice: @invoice1, item: @site1.pending_plan) }

        its(:item)                  { should == @site1.pending_plan }
        its(:price)                 { should == 1000 }
        its(:amount)                { should == 1000 }
        its(:started_at)            { should == @site1.pending_plan_cycle_started_at }
        its(:ended_at)              { should == @site1.pending_plan_cycle_ended_at }
        its(:discounted_percentage) { should be_nil }
      end
    end

    describe "upgrade" do
      # the new upgraded paid plan
      describe "with standard params and a site with pending plan" do
        subject { InvoiceItem::Plan.build(invoice: @invoice2, item: @site2.pending_plan) }

        its(:item)                  { should == @site2.pending_plan }
        its(:price)                 { should == 2000 }
        its(:amount)                { should == 2000 }
        its(:started_at)            { should == @site2.pending_plan_cycle_started_at }
        its(:ended_at)              { should == @site2.pending_plan_cycle_ended_at }
        its(:discounted_percentage) { should be_nil }
      end
      # the old deducted plan
      describe "with deduct params" do
        subject { InvoiceItem::Plan.build(invoice: @invoice2, item: @site2.plan, deduct: true) }

        its(:item)                  { should == @site2.plan }
        its(:price)                 { should == 1000 }
        its(:amount)                { should == -1000 }
        its(:started_at)            { should == @site2.plan_cycle_started_at }
        its(:ended_at)              { should == @site2.plan_cycle_ended_at }
        its(:discounted_percentage) { should be_nil }
      end
    end

    describe "downgrade" do
      # the new downgraded paid plan
      describe "with standard params and a site with pending plan" do
        subject { InvoiceItem::Plan.build(invoice: @invoice3, item: @site3.pending_plan) }

        its(:item)                  { should == @site3.pending_plan }
        its(:price)                 { should == 1000 }
        its(:amount)                { should == 1000 }
        its(:started_at)            { should == @site3.pending_plan_cycle_started_at }
        its(:ended_at)              { should == @site3.pending_plan_cycle_ended_at }
        its(:discounted_percentage) { should be_nil }
      end
    end

  end

end



# == Schema Information
#
# Table name: invoice_items
#
#  id                    :integer         not null, primary key
#  type                  :string(255)
#  invoice_id            :integer
#  item_type             :string(255)
#  item_id               :integer
#  started_at            :datetime
#  ended_at              :datetime
#  discounted_percentage :float
#  price                 :integer
#  amount                :integer
#  created_at            :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#

