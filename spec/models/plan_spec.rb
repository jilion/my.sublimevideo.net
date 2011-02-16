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

    it { should validate_uniqueness_of(:name) }

    it { should validate_numericality_of(:player_hits) }
    it { should validate_numericality_of(:price) }

    it { should allow_value("month").for(:cycle) }
    it { should allow_value("year").for(:cycle) }
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
#  index_plans_on_name  (name) UNIQUE
#

