require 'spec_helper'

describe Plan do
  subject { Factory(:plan) }

  context "Factory" do
    its(:name)          { should =~ /small\d+/ }
    its(:player_hits)   { should == 10_000 }
    its(:price)         { should == 1000 }
    its(:overage_price) { should == 100 }

    it { should be_valid }
  end

  describe "Associations" do
    it { should have_many :sites }
    it { should have_many :invoice_items }
  end

  describe "Validations" do
    [:name, :player_hits, :price, :overage_price].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:player_hits) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:overage_price) }

    it { should validate_uniqueness_of(:name) }

    it { should validate_numericality_of(:player_hits) }
    it { should validate_numericality_of(:price) }
    it { should validate_numericality_of(:overage_price) }
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

end


# == Schema Information
#
# Table name: plans
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  player_hits   :integer
#  price         :integer
#  overage_price :integer
#  created_at    :datetime
#  updated_at    :datetime
#
# Indexes
#
#  index_plans_on_name  (name) UNIQUE
#

