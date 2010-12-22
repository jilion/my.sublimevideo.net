require 'spec_helper'

describe Mail::Log do
  set(:mail_log) { Factory(:mail_log) }
  
  subject { mail_log }
  
  context "with valid attributes" do
    its(:template) { should be_present }
    its(:admin)    { should be_present }
    its(:criteria) { should == ["with_invalid_site"] }
    its(:user_ids) { should == [1,2,3,4,5] }
    
    it { should be_valid }
  end
  
  describe "validates" do
    it { should belong_to :template }
    it { should belong_to :admin }
    
    [:template_id, :admin_id, :criteria, :user_ids].each do |attr|
      it { should allow_mass_assignment_of(attr) }
      it { should validate_presence_of(attr) }
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
# Indexes
#
#  index_mail_logs_on_template_id  (template_id)
#

