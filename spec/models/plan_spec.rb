require 'spec_helper'

describe Plan do
  
  context "with valid attributes" do
    set(:plan) { Factory(:plan) }
    
    subject { plan }
    
    its(:name)          { should == "Personal" }
    its(:term_type)     { should == "month" }
    its(:player_hits)   { should == 10_000 }
    its(:price)         { should == 10 }
    its(:overage_price) { should == 1 }
    
    it { be_valid }
  end
  
  describe "validates" do
    # [:hostname, :dev_hostnames].each do |attr|
    #   it { should allow_mass_assignment_of(attr) }
    # end
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:term_type) }
    it { should validate_presence_of(:player_hits) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:overage_price) }
  end
  
end

# == Schema Information
#
# Table name: plans
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  term_type     :string(255)
#  player_hits   :integer
#  price         :integer
#  overage_price :integer
#  created_at    :datetime
#  updated_at    :datetime
#

