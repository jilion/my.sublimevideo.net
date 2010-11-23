require 'spec_helper'

describe Plan do
  set(:plan) { Factory(:plan) }
  
  context "from factory" do
    subject { plan }
    
    its(:name)          { should =~ /small\d+/ }
    its(:player_hits)   { should == 10_000 }
    its(:price)         { should == 10 }
    its(:overage_price) { should == 1 }
    
    it { should be_valid }
  end
  
  describe "associations" do
    subject { plan }
    
    it { should have_many :sites }
    it { should have_many :invoice_items }
  end
  
  describe "validates" do
    subject { Factory(:plan) }
    
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

