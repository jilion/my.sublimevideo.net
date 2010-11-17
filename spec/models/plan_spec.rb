require 'spec_helper'

describe Plan do
  specify { Plan::TERM_TYPES.should == %w[month year] }
  
  context "from factory" do
    set(:plan_from_factory) { Factory(:plan) }
    subject { plan_from_factory }
    
    its(:name)          { should =~ /small_month_\d+/ }
    its(:term_type)     { should == 'month' }
    its(:player_hits)   { should == 10_000 }
    its(:price)         { should == 10 }
    its(:overage_price) { should == 1 }
    
    it { should be_valid }
  end
  
  describe "associations" do
    set(:plan_for_associations) { Factory(:plan) }
    subject { plan_for_associations }
    
    it { should have_many :sites }
    it { should have_many :invoice_items }
    it { should have_many :addonships }
    it { should have_many :addons }
  end
  
  describe "validates" do
    subject { Factory(:plan) }
    
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

