require 'spec_helper'

describe Admin do
  context "Factory" do
    before(:all) { @admin = Factory.create(:admin) }
    subject { @admin }

    its(:email) { should match /email\d+@admin.com/ }
    its(:roles) { should eq [] }

    it { should be_valid }
  end # Factory

  describe "Module inclusion" do
    it "includes the AdminRoleMethods module" do
      described_class.included_modules.should include(AdminRoleMethods)
    end
  end

  describe "Associations" do
    before(:all) { @admin = Factory.create(:admin) }
    subject { @admin }

    it { should have_many :mail_logs }
  end # Associations

  describe "Validations" do
    before(:all) { @admin = Factory.create(:admin) }
    subject { @admin }

    [:email, :password, :password_confirmation, :remember_me, :roles].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it "can have defined roles" do
      AdminRole.roles.each do |role|
        Factory.build(:admin, roles: [role]).should be_valid
      end
    end

    it "cannot have undefined roles" do
      Factory.build(:admin, roles: ['foo']).should_not be_valid
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
#  password_salt          :string(255)     default(""), not null
#  reset_password_token   :string(255)
#  remember_token         :string(255)
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
#  created_at             :datetime
#  updated_at             :datetime
#  reset_password_sent_at :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  roles                  :text
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_invitation_token      (invitation_token)
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

