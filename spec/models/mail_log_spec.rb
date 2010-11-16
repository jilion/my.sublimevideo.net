require 'spec_helper'

describe MailLog do
  context "from factory" do
    set(:mail_log_from_factory) { Factory(:mail_log) }
    subject { mail_log_from_factory }
    
    its(:template) { should be_present }
    its(:admin)    { should be_present }
    its(:criteria) { should == ["with_activity"] }
    its(:user_ids) { should == [1,2,3,4,5] }
    
    it { should be_valid }
  end
  
  describe "associations" do
    set(:mail_log_for_associations) { Factory(:mail_log) }
    subject { mail_log_for_associations }
    
    it { should belong_to :template }
    it { should belong_to :admin }
  end
  
  describe "validates" do
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

