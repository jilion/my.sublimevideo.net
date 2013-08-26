require 'spec_helper'

describe Admin do
  context "Factory" do
    subject { create(:admin) }

    its(:email) { should match /email\d+@admin.com/ }
    its(:roles) { should eq [] }

    it { should be_valid }
  end # Factory

  describe "Associations" do
    subject { create(:admin) }

    it { should have_many :mail_logs }
  end # Associations

  describe "Validations" do
    subject { create(:admin) }

    it "can have defined roles" do
      Admin.roles.each do |role|
        build(:admin, roles: [role]).should be_valid
      end
    end

    it "cannot have undefined roles" do
      build(:admin, roles: ['foo']).should_not be_valid
    end
  end # Validations

  describe ".has_role?" do
    context "with marcom role" do
      subject { Admin.new(roles: %w[marcom]) }

      it { should have_role('marcom') }
      it { should_not have_role('invoices') }
      it { should_not have_role('god') }
    end

    context "with invoices role" do
      subject { Admin.new(roles: %w[invoices]) }

      it { should have_role('invoices') }
      it { should_not have_role('marcom') }
      it { should_not have_role('god') }
    end

    context "with god role" do
      subject { Admin.new(roles: %w[god]) }

      it { should have_role('god') }
      it { should have_role('marcom') }
      it { should have_role('invoices') }
    end

    context "with 'marcom' and 'invoices' roles" do
      subject { Admin.new(roles: %w[marcom invoices]) }

      it { should have_role('marcom') }
      it { should have_role('invoices') }
      it { should_not have_role('god') }
    end
  end

  it "activates remember_me checkbox by default" do
    build(:admin).remember_me.should be_true
  end
end

# == Schema Information
#
# Table name: admins
#
#  authentication_token   :string(255)
#  created_at             :datetime         not null
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(128)      default(""), not null
#  failed_attempts        :integer          default(0)
#  id                     :integer          not null, primary key
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string(60)
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  locked_at              :datetime
#  password_salt          :string(255)      default(""), not null
#  remember_created_at    :datetime
#  remember_token         :string(255)
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  roles                  :text
#  sign_in_count          :integer          default(0)
#  unconfirmed_email      :string(255)
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_invitation_token      (invitation_token)
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

