require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".construct(attributes = {})" do
    before(:all) do
      @user = FactoryGirl.create(:user, invitation_token: "123asd", created_at: Time.utc(2010,10,10))

      @plan1 = FactoryGirl.create(:plan, price: 1000)
      @plan2 = FactoryGirl.create(:plan, price: 2000)

      Timecop.travel(Time.utc(2011,5,1)) do
        @site1 = FactoryGirl.create(:site_with_invoice, user: @user, plan_id: @plan1.id)

        @site2 = FactoryGirl.create(:site_not_in_trial, user: @user, plan_id: @plan2.id)

        @site3 = FactoryGirl.create(:site_with_invoice, user: @user, plan_id: @plan1.id)
      end

      Timecop.travel(Time.utc(2011,6,15)) do
        # simulate renew of June 1st
        @site1.pend_plan_changes
        @site1.apply_pending_plan_changes
        @site2.pend_plan_changes
        @site2.apply_pending_plan_changes

        # simulate upgrade now
        @site1.plan_id = @plan2.id
        @site1.pend_plan_changes

        # simulate downgrade now
        @site2.plan_id = @plan1.id
        @site2.pend_plan_changes
        @site2.save_without_password_validation

        # normal renew
        @site3.pend_plan_changes
      end

      @invoice1 = FactoryGirl.build(:invoice, site: @site1)
      @invoice2 = FactoryGirl.build(:invoice, site: @site2)
      @invoice3 = FactoryGirl.build(:invoice, site: @site3)
    end

    describe "creation or upgrade" do
      describe "with standard params" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice1, item: @plan2) }

        its(:item)                  { should eql @site1.pending_plan }
        its(:price)                 { should eql 2000 }
        its(:amount)                { should eql 2000 }
        its(:started_at)            { should eql Time.utc(2011,6,1) }
        its(:ended_at)              { should eql Time.utc(2011,6,30).to_datetime.end_of_day }
        its(:discounted_percentage) { should be_nil }
      end

      describe "with deduct params" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice1, item: @plan2, deduct: true) }

        its(:item)                  { should eql @site1.pending_plan }
        its(:price)                 { should eql 1000 }
        its(:amount)                { should eql -1000 }
        its(:started_at)            { should eql Time.utc(2011,6,1) }
        its(:ended_at)              { should eql Time.utc(2011,6,30).to_datetime.end_of_day }
        its(:discounted_percentage) { should be_nil }
      end
    end

    describe "renew" do
      subject { InvoiceItem::Plan.construct(invoice: @invoice3, item: @plan1) }

      its(:item)                  { should eql @site3.plan }
      its(:price)                 { should eql 1000 }
      its(:amount)                { should eql 1000 }
      its(:started_at)            { should eql Time.utc(2011,6,1) }
      its(:ended_at)              { should eql Time.utc(2011,6,30).to_datetime.end_of_day }
      its(:discounted_percentage) { should be_nil }
    end

    describe "downgrade" do
      subject { InvoiceItem::Plan.construct(invoice: @invoice2, item: @plan1) }

      its(:item)                  { should eql @site2.pending_plan }
      its(:price)                 { should eql 1000 }
      its(:amount)                { should eql 1000 }
      its(:started_at)            { should eql @site2.pending_plan_cycle_started_at }
      its(:ended_at)              { should eql @site2.pending_plan_cycle_ended_at }
      its(:discounted_percentage) { should be_nil }
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

