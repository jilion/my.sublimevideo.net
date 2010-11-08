require 'spec_helper'

describe Addon do
  context "with valid attributes" do
    subject { Factory(:addon) }
    
    its(:name)      { should =~ /SSL_\d+/ }
    its(:term_type) { should == 'month' }
    its(:price)     { should == 10 }
    
    it { be_valid }
  end
  
  describe "validates" do
    subject { Factory(:addon) }
    
    it { should have_many :invoice_items }
    it { should have_and_belong_to_many :sites }
    
    [:name, :term_type, :price].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:term_type) }
    it { should validate_presence_of(:price) }
    
    it { should validate_uniqueness_of(:name) }
    
    it { should allow_value('month').for(:term_type) }
    it { should allow_value('year').for(:term_type) }
    it { should_not allow_value('foo').for(:term_type) }
    
    it { should validate_numericality_of(:price) }
  end
end

# == Schema Information
#
# Table name: addons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  term_type  :string(255)
#  price      :integer
#  created_at :datetime
#  updated_at :datetime
#

