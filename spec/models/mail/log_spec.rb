require 'spec_helper'

describe Mail::Log do
  
  subject { Factory(:mail_log) }
  
  context "with valid attributes" do
    its(:template) { should be_present }
    its(:admin)    { should be_present }
    its(:criteria) { should == ["with_activity"] }
    its(:user_ids) { should == [1,2,3,4,5] }
    
    it { should be_valid }
  end
  
  describe "should be invalid" do
    %w[template_id admin_id criteria user_ids].each do |attribute|
      it "without #{attribute}" do
        ml = Factory.build(:mail_log, attribute.to_sym => nil)
        ml.should_not be_valid
        ml.errors[attribute.to_sym].should be_present
      end
    end
  end
  
end

# == Schema Information
#
# Table name: mail_logs
#
#  id          :integer         not null, primary key
#  template_id :integer
#  admin_id    :integer
#  criteria    :text
#  user_ids    :text
#  snapshot    :text
#  created_at  :datetime
#  updated_at  :datetime
#

