require 'spec_helper'

describe Addonship do
  
  context "with valid attributes" do
    set(:addonship_from_factory) { Factory(:addonship) }
    subject { addonship_from_factory }
    
    its(:plan_id)  { should be_present }
    its(:addon_id) { should be_present }
    its(:price)    { should == 99 }
    
    it { should be_valid }
  end
  
  describe "associations" do
    set(:addonship_for_associations) { Factory(:addonship) }
    subject { addonship_for_associations }
    
    it { should belong_to :plan }
    it { should belong_to :addon }
  end
  
end

# == Schema Information
#
# Table name: addonships
#
#  id         :integer         not null, primary key
#  plan_id    :integer
#  addon_id   :integer
#  price      :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_addonships_on_addon_id              (addon_id)
#  index_addonships_on_plan_id               (plan_id)
#  index_addonships_on_plan_id_and_addon_id  (plan_id,addon_id)
#

