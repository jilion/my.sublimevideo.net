require 'spec_helper'

describe Addon do
  context "with valid attributes" do
    set(:addon_from_factory) { Factory(:addon) }
    subject { addon_from_factory }
    
    its(:name)      { should =~ /SSL_\d+/ }
    its(:term_type) { should == 'month' }
    
    it { be_valid }
  end
  
  describe "associations" do
    set(:addon_for_associations) { Factory(:addon) }
    subject { addon_for_associations }
    
    it { should have_and_belong_to_many :sites }
    it { should have_many :invoice_items }
    it { should have_many :addonships }
    it { should have_many :plans }
  end
  
  describe "validates" do
    subject { Factory(:addon) }
    
    [:name, :term_type, :addonships_attributes].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:term_type) }
    
    it { should validate_uniqueness_of(:name) }
    
    it { should allow_value('month').for(:term_type) }
    it { should allow_value('year').for(:term_type) }
    it { should_not allow_value('foo').for(:term_type) }
  end
  
  describe "Instance methods" do
    set(:plan_for_addonships1)  { Factory(:plan) }
    set(:plan_for_addonships2)  { Factory(:plan) }
    set(:addon_for_addonships)  { Factory(:addon, :addonships_attributes => [{ :plan_id => plan_for_addonships1.id, :price => 99 }, { :plan_id => plan_for_addonships2.id, :price => 599 }]) }
    
    describe "#plans" do
      it "should have many plans" do
        addon_for_addonships.plans.should == [plan_for_addonships1, plan_for_addonships2]
      end
    end
    
    describe "#price" do
      it "should have its price exclusively linked to a plan" do
        addon_for_addonships.price(plan_for_addonships1).should == 99
        addon_for_addonships.price(plan_for_addonships2).should == 599
      end
    end
  end
  
end


# == Schema Information
#
# Table name: addons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  term_type  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

