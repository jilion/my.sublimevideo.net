require 'spec_helper'

describe MailLog do

  context "Factory" do
    subject { create(:mail_log) }

    its(:template) { should be_present }
    its(:admin)    { should be_present }
    its(:criteria) { should == ["all"] }
    its(:user_ids) { should == [1,2,3,4,5] }

    it { should be_valid }
  end

  describe "Associations" do
    subject { create(:mail_log) }

    it { should belong_to :template }
    it { should belong_to :admin }
  end

  describe "Validations" do
    [:template_id, :admin_id, :criteria, :user_ids].each do |attr|
      it { should validate_presence_of(attr) }
    end
  end

end

# == Schema Information
#
# Table name: mail_logs
#
#  admin_id    :integer
#  created_at  :datetime
#  criteria    :text
#  id          :integer          not null, primary key
#  snapshot    :text
#  template_id :integer
#  updated_at  :datetime
#  user_ids    :text
#
# Indexes
#
#  index_mail_logs_on_template_id  (template_id)
#

