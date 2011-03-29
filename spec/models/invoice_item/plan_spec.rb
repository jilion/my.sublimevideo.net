require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".build(attributes={})" do
    before(:all) do
      @not_enthusiast = Factory(:user, invitation_token: "123asd")
      @enthusiast     = Factory(:user, invitation_token: nil)

      @plan1 = Factory(:plan, price: 1000)
      @plan2 = Factory(:plan, price: 2000)

      Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do
        @site_without_discount1 = Factory.build(:new_site, user: @not_enthusiast, plan_id: @plan1.id)
        # @site_without_discount1.pend_plan_changes # simulate new or renew
        @site_without_discount2 = Factory(:site_with_invoice, user: @not_enthusiast, plan_id: @plan1.id)
        @site_without_discount2.plan_id = @plan2.id # upgrade
        @site_without_discount2.pend_plan_changes # simulate upgrade
        @site_without_discount3 = Factory(:site, user: @not_enthusiast, plan_id: @plan2.id)
        @site_without_discount3.plan_id = @plan1.id # downgrade
        @site_without_discount3.pend_plan_changes # simulate downgrade

        @site_with_discount1 = Factory.build(:new_site, user: @enthusiast, plan_id: @plan1.id)
        # @site_with_discount1.pend_plan_changes # simulate new or renew
        @site_with_discount2 = Factory(:site_with_invoice, user: @enthusiast, plan_id: @plan1.id)
        @site_with_discount2.plan_id = @plan2.id # upgrade
        @site_with_discount2.pend_plan_changes # simulate upgrade
        @site_with_discount3 = Factory(:site, user: @enthusiast, plan_id: @plan2.id)
        @site_with_discount3.plan_id = @plan1.id # downgrade
        @site_with_discount3.pend_plan_changes # simulate downgrade
      end

      @invoice_without_discount1 = Factory(:invoice, site: @site_without_discount1)
      @invoice_without_discount2 = Factory(:invoice, site: @site_without_discount2)
      @invoice_without_discount3 = Factory(:invoice, site: @site_without_discount3)
      @invoice_with_discount1    = Factory(:invoice, site: @site_with_discount1)
      @invoice_with_discount2    = Factory(:invoice, site: @site_with_discount2)
      @invoice_with_discount3    = Factory(:invoice, site: @site_with_discount3)
    end

    context "with a site that doesn't have the discount" do
      describe "new or renew" do
        describe "with standard params and a site without pending plan" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_without_discount1, item: @site_without_discount1.pending_plan) }

          its(:item)                  { should == @site_without_discount1.pending_plan }
          its(:price)                 { should == 1000 }
          its(:amount)                { should == 1000 }
          its(:started_at)            { should == @site_without_discount1.pending_plan_cycle_started_at }
          its(:ended_at)              { should == @site_without_discount1.pending_plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
      end

      describe "upgrade" do
        # the new upgraded paid plan
        describe "with standard params and a site with pending plan" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_without_discount2, item: @site_without_discount2.pending_plan) }

          its(:item)                  { should == @site_without_discount2.pending_plan }
          its(:price)                 { should == 2000 }
          its(:amount)                { should == 2000 }
          its(:started_at)            { should == @site_without_discount2.pending_plan_cycle_started_at }
          its(:ended_at)              { should == @site_without_discount2.pending_plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
        # the old deducted plan
        describe "with deduct params" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_without_discount2, item: @site_without_discount2.plan, deduct: true) }

          its(:item)                  { should == @site_without_discount2.plan }
          its(:price)                 { should == 1000 }
          its(:amount)                { should == -1000 }
          its(:started_at)            { should == @site_without_discount2.plan_cycle_started_at }
          its(:ended_at)              { should == @site_without_discount2.plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
      end

      describe "downgrade" do
        # the new downgraded paid plan
        describe "with standard params and a site with pending plan" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_without_discount3, item: @site_without_discount3.pending_plan) }

          its(:item)                  { should == @site_without_discount3.pending_plan }
          its(:price)                 { should == 1000 }
          its(:amount)                { should == 1000 }
          its(:started_at)            { should == @site_without_discount3.pending_plan_cycle_started_at }
          its(:ended_at)              { should == @site_without_discount3.pending_plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
      end
    end

    context "with a site that have the discount" do

      describe "new or renew" do
        describe "with standard params and a site without pending plan" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_with_discount1, item: @site_with_discount1.pending_plan) }

          its(:item)                  { should == @site_with_discount1.pending_plan }
          its(:price)                 { should == 800 }
          its(:amount)                { should == 800 }
          its(:started_at)            { should == @site_with_discount1.pending_plan_cycle_started_at }
          its(:ended_at)              { should == @site_with_discount1.pending_plan_cycle_ended_at }
          its(:discounted_percentage) { should == 0.2 }
        end
      end

      describe "upgrade" do
        # the new upgraded paid plan
        describe "with standard params and a site with pending plan" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_with_discount2, item: @site_with_discount2.pending_plan) }

          its(:item)                  { should == @site_with_discount2.pending_plan }
          its(:price)                 { should == 1600 }
          its(:amount)                { should == 1600 }
          its(:started_at)            { should == @site_with_discount2.pending_plan_cycle_started_at }
          its(:ended_at)              { should == @site_with_discount2.pending_plan_cycle_ended_at }
          its(:discounted_percentage) { should == 0.2 }
        end
        # the old deducted plan
        describe "with deduct params" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_with_discount2, item: @site_with_discount2.plan, deduct: true) }

          its(:item)                  { should == @site_with_discount2.plan }
          its(:price)                 { should == 800 }
          its(:amount)                { should == -800 }
          its(:started_at)            { should == @site_with_discount2.plan_cycle_started_at }
          its(:ended_at)              { should == @site_with_discount2.plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
      end

      describe "downgrade" do
        # the new downgraded paid plan
        describe "with standard params and a site with pending plan" do
          subject { InvoiceItem::Plan.build(invoice: @invoice_without_discount3, item: @site_with_discount3.pending_plan) }

          its(:item)                  { should == @site_without_discount3.pending_plan }
          its(:price)                 { should == 1000 }
          its(:amount)                { should == 1000 }
          its(:started_at)            { should == @site_without_discount3.pending_plan_cycle_started_at }
          its(:ended_at)              { should == @site_without_discount3.pending_plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
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

