require 'spec_helper'

describe Admin do
  context "Factory" do
    before(:all) { @admin = Factory(:admin) }
    subject { @admin }

    its(:email) { should match /email\d+@admin.com/ }

    it { should be_valid }
  end # Factory

  describe "Associations" do
    before(:all) { @admin = Factory(:admin) }
    subject { @admin }

    it { should have_many :mail_logs }
  end # Associations

  describe "Validations" do
    before(:all) { @admin = Factory(:admin) }
    subject { @admin }

    [:email, :password, :password_confirmation, :remember_me].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
  end # Validations

end



# == Schema Information
#
# Table name: admins
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  failed_attempts        :integer         default(0)
#  locked_at              :datetime
#  invitation_token       :string(60)
#  invitation_sent_at     :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_invitation_token      (invitation_token)
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

