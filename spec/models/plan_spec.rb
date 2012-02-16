# coding: utf-8
require 'spec_helper'

describe Plan do
  subject { Factory.create(:plan) }

  context "Factory" do
    before(:all) { @plan = Factory.create(:plan) }
    after(:all) { @plan.delete }
    subject { @plan }

    its(:name)                 { should =~ /plus\d+/ }
    its(:cycle)                { should eq "month" }
    its(:video_views)          { should eq 10_000 }
    its(:stats_retention_days) { should eq 365 }
    its(:price)                { should eq 1000 }
    its(:token)                { should =~ /^[a-z0-9]{12}$/ }

    it { should be_valid }
  end

  describe "Scopes" do
    specify { Plan.unpaid_plans.all.should =~ [@free_plan, @sponsored_plan] }
    specify { Plan.paid_plans.all.should =~ [@paid_plan, @custom_plan] }
    specify { Plan.standard_plans.all.should =~ [@paid_plan] }
    specify { Plan.custom_plans.all.should =~ [@custom_plan] }
  end

  describe "Associations" do
    it { should have_many :sites }
    it { should have_many :invoice_items }
  end

  describe "Validations" do
    [:name, :cycle, :video_views, :price, :support_level].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:video_views) }
    it { should validate_presence_of(:cycle) }
    it { should validate_presence_of(:support_level) }

    it "price can't be blank" do
      Factory.build(:plan, price: nil).should have(1).error_on(:price)
    end

    describe "uniqueness of name scoped by cycle" do
      before(:each) do
        Factory.create(:plan, :name => "foo", :cycle => "month")
      end

      it { Factory.build(:plan, :name => "foo", :cycle => "month").should_not be_valid }
      it { Factory.build(:plan, :name => "foo", :cycle => "year").should be_valid }
    end

    it { should validate_numericality_of(:video_views) }

    it { should allow_value("month").for(:cycle) }
    it { should allow_value("year").for(:cycle) }
    it { should allow_value("none").for(:cycle) }
    it { should_not allow_value("foo").for(:cycle) }
  end

  describe "Class Methods" do
    describe ".create_custom" do
      it "should create new custom plan" do
        expect { @plan = Plan.create_custom(name: 'bob', cycle: "month", video_views: 10**7, price: 999900) }.to change(Plan.custom_plans, :count).by(1)
        @plan.name.should eq "custom - bob"
      end
    end
  end

  describe "Instance Methods" do
    describe "#next_plan" do
      it "should return the next plan with a bigger price" do
        plan2 = Factory.create(:plan, price: subject.price + 100)
        plan3 = Factory.create(:plan, price: subject.price + 2000)
        @paid_plan.next_plan.should eq plan2
      end

      it "should be_nil if none bigger plan exist" do
        plan2 = Factory.create(:plan, price: 10**9)
        plan2.next_plan.should be_nil
      end
    end

    describe "#month_price" do
      context "with month plan" do
        subject { Factory.build(:plan, :cycle => "month", :price => 1000) }

        its(:month_price) { should eq 1000 }
      end

      context "with year plan" do
        subject { Factory.build(:plan, :cycle => "year", :price => 10000) }

        its(:month_price) { should eq 10000 / 12 }
      end
    end

    describe "#free_plan?" do
      it { Factory.build(:plan, :name => "free").should be_free_plan }
      it { Factory.build(:plan, :name => "pro").should_not be_free_plan }
    end

    describe "#sponsored_plan?" do
      it { Factory.build(:plan, :name => "free").should_not be_sponsored_plan }
      it { Factory.build(:plan, :name => "pro").should_not be_sponsored_plan }
      it { Factory.build(:plan, :name => "sponsored").should be_sponsored_plan }
    end

    describe "#standard_plan?" do
      it { Factory.build(:plan, :name => "free").should_not be_standard_plan }
      it { Factory.build(:plan, :name => "sponsored").should_not be_standard_plan }

      Plan::STANDARD_NAMES.each do |name|
        it { Factory.build(:plan, :name => name).should be_standard_plan }
      end
    end

    describe "#custom_plan?" do
      it { Factory.build(:plan, :name => "free").should_not be_custom_plan }
      it { Factory.build(:plan, :name => "sponsored").should_not be_custom_plan }
      it { Factory.build(:plan, :name => "comet").should_not be_custom_plan }
      it { Factory.build(:plan, :name => "custom").should be_custom_plan }
      it { Factory.build(:plan, :name => "custom1").should be_custom_plan }
      it { Factory.build(:plan, :name => "custom2").should be_custom_plan }
    end

    describe "#unpaid_plan?" do
      it { Factory.build(:plan, :name => "free").should be_unpaid_plan }
      it { Factory.build(:plan, :name => "sponsored").should be_unpaid_plan }
      it { Factory.build(:plan, :name => "comet").should_not be_unpaid_plan }
      it { Factory.build(:plan, :name => "custom").should_not be_unpaid_plan }
      it { Factory.build(:plan, :name => "custom1").should_not be_unpaid_plan }
      it { Factory.build(:plan, :name => "custom2").should_not be_unpaid_plan }
    end

    describe "#paid_plan?" do
      it { Factory.build(:plan, :name => "free").should_not be_paid_plan }
      it { Factory.build(:plan, :name => "sponsored").should_not be_paid_plan }
      it { Factory.build(:plan, :name => "comet").should be_paid_plan }
      it { Factory.build(:plan, :name => "custom").should be_paid_plan }
      it { Factory.build(:plan, :name => "custom1").should be_paid_plan }
      it { Factory.build(:plan, :name => "custom2").should be_paid_plan }
    end

    describe "#monthly?, #yearly? and #nonely?" do
      it { Factory.build(:plan, cycle: "month").should be_monthly }
      it { Factory.build(:plan, cycle: "year").should be_yearly }
      it { Factory.build(:plan, cycle: "none").should be_nonely }
    end

    describe "#upgrade?" do
      before(:all) do
        @paid_plan         = Factory.build(:plan, cycle: "month", price: 1000)
        @paid_plan2        = Factory.build(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = Factory.build(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = Factory.build(:plan, cycle: "year",  price: 50000)
      end

      it { @free_plan.upgrade?(nil).should be_false }
      it { @free_plan.upgrade?(@free_plan).should be_nil }
      it { @free_plan.upgrade?(@paid_plan).should be_true }
      it { @free_plan.upgrade?(@paid_plan2).should be_true }
      it { @free_plan.upgrade?(@paid_plan_yearly).should be_true }
      it { @free_plan.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan.upgrade?(nil).should be_false }
      it { @paid_plan.upgrade?(@free_plan).should be_false }
      it { @paid_plan.upgrade?(@paid_plan).should be_nil }
      it { @paid_plan.upgrade?(@paid_plan2).should be_true }
      it { @paid_plan.upgrade?(@paid_plan_yearly).should be_true }
      it { @paid_plan.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan2.upgrade?(nil).should be_false }
      it { @paid_plan2.upgrade?(@free_plan).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan2).should be_nil }
      it { @paid_plan2.upgrade?(@paid_plan_yearly).should be_false }
      it { @paid_plan2.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan_yearly.upgrade?(nil).should be_false }
      it { @paid_plan_yearly.upgrade?(@free_plan).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan2).should be_false }
      it { @paid_plan_yearly.upgrade?(@paid_plan_yearly).should be_nil }
      it { @paid_plan_yearly.upgrade?(@paid_plan_yearly2).should be_true }

      it { @paid_plan_yearly2.upgrade?(nil).should be_false }
      it { @paid_plan_yearly2.upgrade?(@free_plan).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan2).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly).should be_false }
      it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly2).should be_nil }
    end

    describe "#title" do
      specify { @free_plan.title.should eq "Free" }
      specify { @free_plan.title(always_with_cycle: true).should eq "Free" }
      specify { @sponsored_plan.title.should eq "Sponsored" }
      specify { @sponsored_plan.title(always_with_cycle: true).should eq "Sponsored" }
      specify { @custom_plan.title.should eq "Custom" }
      specify { @custom_plan.title(always_with_cycle: true).should eq "Custom (monthly)" }
      specify { Factory.build(:plan, cycle: "month", name: "comet").title.should eq "Comet" }
      specify { Factory.build(:plan, cycle: "year", name: "comet").title.should eq "Comet (yearly)" }
      specify { Factory.build(:plan, cycle: "month", name: "comet").title(always_with_cycle: true).should eq "Comet (monthly)" }
      specify { Factory.build(:plan, cycle: "year", name: "comet").title(always_with_cycle: true).should eq "Comet (yearly)" }
    end

    describe "#daily_video_views" do
      before(:all) do
        @plan1 = Factory.build(:plan, cycle: "month", video_views: 1000)
        @plan2 = Factory.build(:plan, cycle: "year", video_views: 2000)
        @plan3 = Factory.build(:plan, cycle: "none", video_views: 3000)
      end

      it { @plan1.daily_video_views.should eq 33 }
      it { @plan2.daily_video_views.should eq 66 }
      it { @plan3.daily_video_views.should eq 100 }
    end

    describe "#support" do
      it { Factory.build(:plan, name: "free", support_level: 0).support.should eq "forum" }
      it { Factory.build(:plan, name: "plus", support_level: 1).support.should eq "email" }
      it { Factory.build(:plan, name: "premium", support_level: 2).support.should eq "vip_email" }
    end

    describe "#discounted?" do
      let(:user)  { Factory(:user) }
      let(:site1) { Factory(:site) }
      let(:site2) { Factory(:site, user: user) }
      let(:deal1) { Factory(:deal, kind: 'plans_discount', value: 0.3, started_at: 2.days.ago, ended_at: 2.days.from_now) }
      let(:deal2) { Factory(:deal, kind: 'yearly_plans_discount', value: 0.3, started_at: 2.days.ago, ended_at: 2.days.from_now) }
      let(:plan1) { Factory(:plan, name: 'foo', cycle: 'month') }
      let(:plan2) { Factory(:plan, name: 'bar', cycle: 'year') }

      context "site's user doesn't have access to a discounted price" do
        it "return false" do
          subject.discounted?(site1).should be_nil
        end
      end

      context "site's user has access to a discounted price" do
        it "price isn't discounted for this plan" do
          Factory(:deal_activation, deal: deal2, user: user)
          plan1.discounted?(site2).should be_nil
        end

        it "price is discounted for this plan" do
          Factory(:deal_activation, deal: deal2, user: user)
          plan2.discounted?(site2).should eq deal2
        end

        it "price is discounted for this plan" do
          Factory(:deal_activation, deal: deal1, user: user)
          plan1.discounted?(site2).should eq deal1
        end

        it "price is discounted for this plan" do
          Factory(:deal_activation, deal: deal1, user: user)
          plan2.discounted?(site2).should eq deal1
        end

        context "site trial started during deal" do
          it "price is discounted for this plan" do
            Factory(:deal_activation, deal: deal2, user: user)
            site2.trial_started_at.should eq Time.now.utc.midnight

            Timecop.travel(3.days.from_now) do
              deal2.should_not be_active
              plan2.discounted?(site2).should eq deal2
            end
          end
        end

        context "site trial started after the deal end" do
          it "price isn't discounted for this plan" do
            Factory(:deal_activation, deal: deal2, user: user)

            Timecop.travel(3.days.from_now) do
              site2.trial_started_at.should eq Time.now.utc.midnight
              deal2.should_not be_active
              plan2.discounted?(site2).should be_nil
            end
          end
        end
      end
    end

    describe "#discounted_percentage" do
      let(:site) { Factory(:site) }
      let(:deal) { Factory(:deal, value: 0.3) }
      subject { Factory.create(:plan) }

      context "site doesn't have access to a discounted price" do
        before(:each) do
          subject.should_receive(:discounted?).with(site) { false }
        end

        it "return 0" do
          subject.discounted_percentage(site).should eq 0
        end
      end

      context "site has access to a discounted price" do
        before(:each) do
          subject.should_receive(:discounted?).with(site) { deal }
        end

        it "return the deal's value" do
          subject.discounted_percentage(site).should eq deal.value
        end
      end
    end

    describe "#price" do
      let(:site) { Factory(:site) }
      subject { Factory.create(:plan) }

      context "site doesn't have access to a discounted price" do
        before(:each) do
          subject.should_receive(:discounted_percentage).with(site) { 0 }
        end

        it "price is not discounted" do
          subject.price(site).should eq subject.read_attribute(:price) * (1 - 0)
        end
      end

      context "site has access to a discounted price" do
        before(:each) do
          subject.should_receive(:discounted_percentage).with(site) { 0.3 }
        end

        it "price is discounted" do
          subject.price(site).should eq subject.read_attribute(:price) * (1 - 0.3)
        end
      end
    end

  end

end
# == Schema Information
#
# Table name: plans
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  token                :string(255)
#  cycle                :string(255)
#  video_views          :integer
#  price                :integer
#  created_at           :datetime
#  updated_at           :datetime
#  support_level        :integer         default(0)
#  stats_retention_days :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#
