require 'spec_helper'

describe Addon do
  
  describe "Factory" do
    before(:all) { @addon = Factory(:addon) }
    subject { @addon }
    
    its(:name) { should =~ /SSL_\d+/ }
    
    it { should be_valid }
  end # Factory
  
  describe "Associations" do
    before(:all) { @addon = Factory(:addon) }
    subject { @addon }
    
    it { should have_and_belong_to_many :sites }
    it { should have_many :invoice_items }
  end # Associations
  
  describe "Validations" do
    before(:all) { @addon = Factory(:addon) }
    subject { @addon }
    
    [:name, :price].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price) }
  end # Validations
  
end


# == Schema Information
#
# Table name: addons
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  price      :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

