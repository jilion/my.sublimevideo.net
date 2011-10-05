require 'spec_helper'

describe InvoiceItem::Plan do

  describe ".build(attributes={})" do
    before(:all) do
      @user = FactoryGirl.create(:user, invitation_token: "123asd", created_at: Time.utc(2010,10,10))

      @plan1 = FactoryGirl.create(:plan, price: 1000)
      @plan2 = FactoryGirl.create(:plan, price: 2000)

      Timecop.travel(Time.utc(2011,5,1)) do
        @site1 = FactoryGirl.build(:new_site, user: @user, plan_id: @plan1.id)

        @site2 = FactoryGirl.create(:site_with_invoice, user: @user, plan_id: @plan1.id)

        @site3 = FactoryGirl.create(:site_not_in_trial, user: @user, plan_id: @plan2.id)

        @site4 = FactoryGirl.create(:site_with_invoice, user: @user, plan_id: @plan1.id)
      end

      Timecop.travel(Time.utc(2011,6,1)) do
        # simulate upgrade now
        @site2.plan_id = @plan2.id
        @site2.pend_plan_changes

        # simulate downgrade now
        @site3.plan_id = @plan1.id
        @site3.pend_plan_changes
        @site3.save_without_password_validation
      end

      @invoice1 = FactoryGirl.create(:invoice, site: @site1)
      @invoice2 = FactoryGirl.create(:invoice, site: @site2)
      @invoice3 = FactoryGirl.create(:invoice, site: @site3)
      @invoice4 = FactoryGirl.create(:invoice, site: @site4)
    end

    describe "new or renew" do
      describe "with standard params and a site with pending plan" do
        subject { InvoiceItem::Plan.build(invoice: @invoice1, item: @site1.plan) }

        its(:item)                  { should eql @site1.plan }
        its(:price)                 { should eql 1000 }
        its(:amount)                { should eql 1000 }
        its(:started_at)            { should eql @site1.pending_plan_cycle_started_at }
        its(:ended_at)              { should eql @site1.pending_plan_cycle_ended_at }
        its(:discounted_percentage) { should be_nil }
      end
    end

    describe "upgrade" do
      context "a site with a pending plan" do
        # the new upgraded paid plan
        describe "with standard params" do
          subject { InvoiceItem::Plan.build(invoice: @invoice2, item: @site2.pending_plan) }

          its(:item)                  { should eql @site2.pending_plan }
          its(:price)                 { should eql 2000 }
          its(:amount)                { should eql 2000 }
          its(:started_at)            { should eql @site2.pending_plan_cycle_started_at }
          its(:ended_at)              { should eql @site2.pending_plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end

        # the old deducted plan
        describe "with deduct params" do
          subject { InvoiceItem::Plan.build(invoice: @invoice2, item: @site2.plan, deduct: true) }

          its(:item)                  { should eql @site2.plan }
          its(:price)                 { should eql 1000 }
          its(:amount)                { should eql -1000 }
          its(:started_at)            { should eql @site2.plan_cycle_started_at }
          its(:ended_at)              { should eql @site2.plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
      end

      context "a site without a pending plan" do
        # the new upgraded paid plan
        describe "with standard params" do
          subject { InvoiceItem::Plan.build(invoice: @invoice4, item: @site4.plan) }

          its(:item)                  { should eql @site4.plan }
          its(:price)                 { should eql 1000 }
          its(:amount)                { should eql 1000 }
          its(:started_at)            { should eql @site4.plan_cycle_started_at }
          its(:ended_at)              { should eql @site4.plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end

        # the old deducted plan
        describe "with deduct params" do
          subject { InvoiceItem::Plan.build(invoice: @invoice4, item: @site4.plan, deduct: true) }

          its(:item)                  { should eql @site4.plan }
          its(:price)                 { should eql 1000 }
          its(:amount)                { should eql -1000 }
          its(:started_at)            { should eql @site4.plan_cycle_started_at }
          its(:ended_at)              { should eql @site4.plan_cycle_ended_at }
          its(:discounted_percentage) { should be_nil }
        end
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

