require 'spec_helper'

describe InvoiceItem::Plan, :plans do

  context "Factory" do
    let(:invoice_item) { create(:plan_invoice_item) }
    subject { invoice_item }

    its(:invoice)   { should be_present }
    its(:site)      { should eq invoice_item.invoice.site }
    its(:user)      { should eq invoice_item.site.user }
    its(:type)      { should eq 'InvoiceItem::Plan' }
    its(:item_type) { should eq 'Plan' }
    its(:item_id)   { should be_present }
    specify         { subject.started_at.to_i.should eq Time.now.utc.beginning_of_month.to_i }
    specify         { subject.ended_at.to_i.should eq Time.now.utc.end_of_month.to_i }
    its(:price)     { should eq 1000 }
    its(:amount)    { should eq 1000 }

    it { should be_valid }
  end # Factory

  describe ".construct" do
    before(:all) do
      @deal = create(:deal, value: 0.2, kind: 'plans_discount', started_at: 2.days.ago, ended_at: 2.days.from_now)
      @user1 = create(:user)
      @user2 = create(:user)
      @user3 = create(:user)
      create(:deal_activation, deal: @deal, user: @user1)
      create(:deal_activation, deal: @deal, user: @user3)

      @plan1 = create(:plan, price: 1000)
      @plan2 = create(:plan, price: 2000)

      @site1 = create(:site_with_invoice, user: @user1, plan_id: @plan1.id)
      @site2 = create(:site, user: @user1, plan_id: @plan2.id)
      @site3 = create(:site_with_invoice, user: @user1, plan_id: @plan1.id)
      @site4 = create(:site_with_invoice, user: @user2, plan_id: @plan1.id)
      @site5 = create(:site_with_invoice, user: @user1, plan_id: @plan1.id)

      @site6 = create(:site_with_invoice, user: @user3, plan_id: @plan1.id)

      Timecop.travel(45.days.from_now) do
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
        @site2.skip_password(:save!)

        # normal renew
        @site3.prepare_pending_attributes
      end

      @invoice1 = build(:invoice, site: @site1)
      @invoice2 = build(:invoice, site: @site2, renew: true)
      @invoice3 = build(:invoice, site: @site3, renew: true)
      @invoice4 = build(:invoice, site: @site4)
      @invoice5 = build(:invoice, site: @site5)
      @invoice6 = build(:invoice, site: @site6)
    end
    after(:all) { DatabaseCleaner.clean_with(:truncation) }

    describe "creation or upgrade" do
      context "upgrade with a deal" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice1, item: @plan2) }

        its(:item)                  { should eq @plan2 }
        its(:deal)                  { should eq @deal }
        its(:discounted_percentage) { should eq @deal.value }
        its(:price)                 { should eq @plan2.price * (1-@deal.value) }
        its(:amount)                { should eq @plan2.price * (1-@deal.value) }
        its(:started_at)            { should eq @site1.pending_plan_cycle_started_at }
        its(:ended_at)              { should eq @site1.pending_plan_cycle_ended_at }
      end

      context "upgrade with deduct params (deducted plan)" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice1, item: @plan1, deduct: true) }

        its(:item)                  { should eq @plan1 }
        its(:deal)                  { should be_nil }
        its(:discounted_percentage) { should eq 0 }
        its(:price)                 { should eq @plan1.price * (1-@deal.value) }
        its(:amount)                { should eq -@plan1.price * (1-@deal.value) }
        its(:started_at)            { should eq @site1.plan_cycle_started_at }
        its(:ended_at)              { should eq @site1.plan_cycle_ended_at }
      end

      context "with trial ended and started during the deal" do
        subject do
          Timecop.travel(3.days.from_now) { @ii = InvoiceItem::Plan.construct(invoice: @invoice6, item: @plan1) }
          @ii
        end

        its(:item)                  { should eq @plan1 }
        its(:deal)                  { should eq @deal }
        its(:discounted_percentage) { should eq @deal.value }
        its(:price)                 { should eq @plan1.price * (1-@deal.value) }
        its(:amount)                { should eq @plan1.price * (1-@deal.value) }
        its(:started_at)            { should eq @site6.plan_cycle_started_at }
        its(:ended_at)              { should eq @site6.plan_cycle_ended_at }
      end

      context "in paid plan during the deal" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice5, item: @plan2) }

        its(:item)                  { should eq @plan2 }
        its(:deal)                  { should eq @deal }
        its(:discounted_percentage) { should eq @deal.value }
        its(:price)                 { should eq @plan2.price * (1-@deal.value) }
        its(:amount)                { should eq @plan2.price * (1-@deal.value) }
        its(:started_at)            { should eq @site5.plan_cycle_started_at }
        its(:ended_at)              { should eq @site5.plan_cycle_ended_at }
      end

      context "with standard params and no deal" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice4, item: @plan2) }

        its(:item)                  { should eq @plan2 }
        its(:deal)                  { should be_nil }
        its(:discounted_percentage) { should eq 0 }
        its(:price)                 { should eq @plan2.price }
        its(:amount)                { should eq @plan2.price }
        its(:started_at)            { should eq @site4.plan_cycle_started_at }
        its(:ended_at)              { should eq @site4.plan_cycle_ended_at }
      end
    end

    describe "renew" do
      context "without downgrade" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice3, item: @plan1) }

        its(:item)                  { should eq @plan1 }
        its(:deal)                  { should be_nil }
        its(:discounted_percentage) { should eq 0 }
        its(:price)                 { should eq @plan1.price }
        its(:amount)                { should eq @plan1.price }
        its(:started_at)            { should eq @site3.pending_plan_cycle_started_at }
        its(:ended_at)              { should eq @site3.pending_plan_cycle_ended_at }
      end

      context "with downgrade" do
        subject { InvoiceItem::Plan.construct(invoice: @invoice2, item: @plan1) }

        its(:item)                  { should eq @plan1 }
        its(:deal)                  { should be_nil }
        its(:discounted_percentage) { should eq 0 }
        its(:price)                 { should eq @plan1.price }
        its(:amount)                { should eq @plan1.price }
        its(:started_at)            { should eq @site2.plan_cycle_started_at }
        its(:ended_at)              { should eq @site2.plan_cycle_ended_at }
      end
    end

  end

end

# == Schema Information
#
# Table name: plans
#
#  created_at           :datetime         not null
#  cycle                :string(255)
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  price                :integer
#  stats_retention_days :integer
#  support_level        :integer          default(0)
#  token                :string(255)
#  updated_at           :datetime         not null
#  video_views          :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

