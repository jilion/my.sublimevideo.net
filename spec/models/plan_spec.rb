require 'spec_helper'

describe Plan do
  describe Plan::TERM_TYPES do
    it { should == %w[month year] }
  end
  
  context "with valid attributes" do
    subject { Factory(:plan) }
    
    its(:name)          { should == 'small_month' }
    its(:term_type)     { should == 'month' }
    its(:player_hits)   { should == 10_000 }
    its(:price)         { should == 10 }
    its(:overage_price) { should == 1 }
    
    it { be_valid }
  end
  
  describe "validates" do
    subject { Factory(:plan) }
    
    it { should have_many :sites }
    it { should have_many :invoice_items }
    
    [:name, :term_type, :player_hits, :price, :overage_price].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:term_type) }
    it { should validate_presence_of(:player_hits) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:overage_price) }
    
    it { should validate_uniqueness_of(:name) }
    
    it { should allow_value('month').for(:term_type) }
    it { should allow_value('year').for(:term_type) }
    it { should_not allow_value('foo').for(:term_type) }
    
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
#  term_type     :string(255)
#  player_hits   :integer
#  price         :integer
#  overage_price :integer
#  created_at    :datetime
#  updated_at    :datetime
#
