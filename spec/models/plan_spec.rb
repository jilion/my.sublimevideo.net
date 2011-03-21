require 'spec_helper'

describe Plan do
  subject { Factory(:plan) }

  context "Factory" do
    its(:name)          { should =~ /small\d+/ }
    its(:cycle)         { should == "month" }
    its(:player_hits)   { should == 10_000 }
    its(:price)         { should == 1000 }

    it { should be_valid }
  end

  describe "Associations" do
    it { should have_many :sites }
    it { should have_many :invoice_items }
  end

  describe "Validations" do
    [:name, :cycle, :player_hits, :price].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:player_hits) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:cycle) }

    describe "uniqueness of name scoped by cycle" do
      before(:each) do
        Factory(:plan, :name => "foo", :cycle => "month")
      end

      it { Factory.build(:plan, :name => "foo", :cycle => "month").should_not be_valid }
      it { Factory.build(:plan, :name => "foo", :cycle => "year").should be_valid }
    end

    it { should validate_numericality_of(:player_hits) }
    it { should validate_numericality_of(:price) }

    it { should allow_value("month").for(:cycle) }
    it { should allow_value("year").for(:cycle) }
    it { should allow_value("none").for(:cycle) }
    it { should_not allow_value("foo").for(:cycle) }
  end

  describe "#next_plan" do
    it "should return the next plan with a bigger price" do
      plan2 = Factory(:plan, :price => subject.price + 100)
      plan3 = Factory(:plan, :price => subject.price + 2000)
      subject.next_plan.should == plan2
    end

    it "should be_nil if none bigger plan exist" do
      plan2 = Factory(:plan, :price => subject.price - 100)
      subject.next_plan.should be_nil
    end
  end

  describe "#month_price" do
    context "with month plan" do
      subject { Factory(:plan, :cycle => "month", :price => 1000) }

      its(:month_price) { should == 1000 }
    end

    context "with year plan" do
      subject { Factory(:plan, :cycle => "year", :price => 10000) }

      its(:month_price) { should == 10000 / 12 }
    end
  end

  describe "#dev_plan?" do
    it { Factory(:plan, :name => "dev").should be_dev_plan }
    it { Factory(:plan, :name => "pro").should_not be_dev_plan }
  end

  describe "#beta_plan?" do
    it { Factory(:plan, :name => "beta").should be_beta_plan }
    it { Factory(:plan, :name => "dev").should_not be_beta_plan }
  end

  describe "#monthly?, #yearly? and #nonely?" do
    it { Factory(:plan, cycle: "month").should be_monthly }
    it { Factory(:plan, cycle: "year").should be_yearly }
    it { Factory(:plan, cycle: "none").should be_nonely }
  end

  describe "#upgrade?" do
    before(:all) do
      @paid_plan         = Factory(:plan, cycle: "month", price: 1000)
      @paid_plan2        = Factory(:plan, cycle: "month", price: 5000)
      @paid_plan_yearly  = Factory(:plan, cycle: "year",  price: 10000)
      @paid_plan_yearly2 = Factory(:plan, cycle: "year",  price: 50000)
    end

    it { @dev_plan.upgrade?(@dev_plan).should be_nil }
    it { @dev_plan.upgrade?(@paid_plan).should be_true }
    it { @dev_plan.upgrade?(@paid_plan2).should be_true }
    it { @dev_plan.upgrade?(@paid_plan_yearly).should be_true }
    it { @dev_plan.upgrade?(@paid_plan_yearly2).should be_true }

    it { @paid_plan.upgrade?(@dev_plan).should be_false }
    it { @paid_plan.upgrade?(@paid_plan).should be_nil }
    it { @paid_plan.upgrade?(@paid_plan2).should be_true }
    it { @paid_plan.upgrade?(@paid_plan_yearly).should be_true }
    it { @paid_plan.upgrade?(@paid_plan_yearly2).should be_true }

    it { @paid_plan2.upgrade?(@dev_plan).should be_false }
    it { @paid_plan2.upgrade?(@paid_plan).should be_false }
    it { @paid_plan2.upgrade?(@paid_plan2).should be_nil }
    it { @paid_plan2.upgrade?(@paid_plan_yearly).should be_false }
    it { @paid_plan2.upgrade?(@paid_plan_yearly2).should be_true }

    it { @paid_plan_yearly.upgrade?(@dev_plan).should be_false }
    it { @paid_plan_yearly.upgrade?(@paid_plan).should be_false }
    it { @paid_plan_yearly.upgrade?(@paid_plan2).should be_false }
    it { @paid_plan_yearly.upgrade?(@paid_plan_yearly).should be_nil }
    it { @paid_plan_yearly.upgrade?(@paid_plan_yearly2).should be_true }

    it { @paid_plan_yearly2.upgrade?(@dev_plan).should be_false }
    it { @paid_plan_yearly2.upgrade?(@paid_plan).should be_false }
    it { @paid_plan_yearly2.upgrade?(@paid_plan2).should be_false }
    it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly).should be_false }
    it { @paid_plan_yearly2.upgrade?(@paid_plan_yearly2).should be_nil }
  end

  describe "#title", focus: true do

    specify { @dev_plan.title.should == "Free Sandbox" }
    specify { @dev_plan.title(always_with_cycle: true).should == "Free Sandbox" }
    specify { Factory(:plan, cycle: "month", name: "comet").title.should == "Comet" }
    specify { Factory(:plan, cycle: "year", name: "comet").title.should == "Comet (yearly)" }
    specify { Factory(:plan, cycle: "month", name: "comet").title(always_with_cycle: true).should == "Comet (monthly)" }
    specify { Factory(:plan, cycle: "year", name: "comet").title(always_with_cycle: true).should == "Comet (yearly)" }

  end

end


# == Schema Information
#
# Table name: plans
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  cycle       :string(255)
#  player_hits :integer
#  price       :integer
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#

