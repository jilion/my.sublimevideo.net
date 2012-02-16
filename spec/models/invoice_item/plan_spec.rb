require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".construct(attributes = {})" do
    before(:all) do
      @deal = Factory(:deal, value: 0.2, kind: 'plans_discount', started_at: 2.days.ago, ended_at: 2.days.from_now)
      @user1 = Factory(:user)
      @user2 = Factory(:user)
      Factory(:deal_activation, deal: @deal, user: @user1)

      @plan1 = Factory(:plan, price: 1000)
      @plan2 = Factory(:plan, price: 2000)

      Timecop.travel(Time.utc(2011,5,1)) do
        @site1 = Factory(:site_with_invoice, user: @user1, plan_id: @plan1.id)
        @site2 = Factory(:site_not_in_trial, user: @user1, plan_id: @plan2.id)
        @site3 = Factory(:site_with_invoice, user: @user1, plan_id: @plan1.id)
        @site4 = Factory(:site_with_invoice, user: @user2, plan_id: @plan1.id)
        @site5 = Factory(:site_with_invoice, user: @user1, plan_id: @plan1.id)
      end

      Timecop.travel(Time.utc(2011,6,15)) do
        # simulate renew of June 1st
        @site1.prepare_pending_attributes
        @site1.apply_pending_attributes
        @site2.prepare_pending_attributes
        @site2.apply_pending_attributes

        # simulate upgrade now
        @site1.plan_id = @plan2.id
        @site1.prepare_pending_attributes

        # simulate downgrade now
        @site2.plan_id = @plan1.id
        @site2.prepare_pending_attributes
        @site2.save_skip_pwd

        # normal renew
        @site3.prepare_pending_attributes
      end
      @site5.skip_trial = true

      @invoice1 = Factory.build(:invoice, site: @site1)
      @invoice2 = Factory.build(:invoice, site: @site2)
      @invoice3 = Factory.build(:invoice, site: @site3)
      @invoice4 = Factory.build(:invoice, site: @site4)
      @invoice5 = Factory.build(:invoice, site: @site5)
    end

    describe "creation or upgrade" do
      context "with standard params and a deal" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice1, item: @plan2) }

        its(:item)                  { should eq @plan2 }
        its(:deal)                  { should eq @deal }
        its(:price)                 { should eq 2000 * (1-@deal.value) }
        its(:amount)                { should eq 2000 * (1-@deal.value) }
        its(:started_at)            { should eq Time.utc(2011,6,1) }
        its(:ended_at)              { should eq Time.utc(2011,6,30).to_datetime.end_of_day }
        its(:discounted_percentage) { should eq @deal.value }
      end

      context "with standard params, site skip trial and a deal" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice5, item: @plan2) }

        its(:item)                  { should eq @plan2 }
        its(:deal)                  { should eq @deal }
        its(:price)                 { should eq 2000 * (1-@deal.value) }
        its(:amount)                { should eq 2000 * (1-@deal.value) }
        its(:started_at)            { should eq Time.utc(2011,5,1) }
        its(:ended_at)              { should eq Time.utc(2011,5,31).to_datetime.end_of_day }
        its(:discounted_percentage) { should eq @deal.value }
      end

      context "with standard params and no deal" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice4, item: @plan2) }

        its(:item)                  { should eq @plan2 }
        its(:deal)                  { should be_nil }
        its(:price)                 { should eq 2000 }
        its(:amount)                { should eq 2000 }
        its(:started_at)            { should eq Time.utc(2011,5,1) }
        its(:ended_at)              { should eq Time.utc(2011,5,31).to_datetime.end_of_day }
        its(:discounted_percentage) { should eq 0 }
      end

      context "with deduct params" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice1, item: @plan2, deduct: true) }

        its(:item)                  { should eq @plan2 }
        its(:deal)                  { should be_nil }
        its(:price)                 { should eq 800 }
        its(:amount)                { should eq -800 }
        its(:started_at)            { should eq Time.utc(2011,6,1) }
        its(:ended_at)              { should eq Time.utc(2011,6,30).to_datetime.end_of_day }
        its(:discounted_percentage) { should eq 0 }
      end
    end

    describe "renew" do
      subject { InvoiceItem::Plan.construct(invoice: @invoice3, item: @plan1) }

      its(:item)                  { should eq @plan1 }
      its(:deal)                  { should be_nil }
      its(:price)                 { should eq 1000 }
      its(:amount)                { should eq 1000 }
      its(:started_at)            { should eq Time.utc(2011,6,1) }
      its(:ended_at)              { should eq Time.utc(2011,6,30).to_datetime.end_of_day }
      its(:discounted_percentage) { should eq 0 }
    end

    describe "downgrade" do
      subject { InvoiceItem::Plan.construct(invoice: @invoice2, item: @plan1) }

      its(:item)                  { should eq @plan1 }
      its(:deal)                  { should be_nil }
      its(:price)                 { should eq 1000 }
      its(:amount)                { should eq 1000 }
      its(:started_at)            { should eq @site2.pending_plan_cycle_started_at }
      its(:ended_at)              { should eq @site2.pending_plan_cycle_ended_at }
      its(:discounted_percentage) { should eq 0 }
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

