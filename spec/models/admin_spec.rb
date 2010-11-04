require 'spec_helper'

describe Admin do
  context "with valid attributes" do
    subject { Factory(:admin) }
    
    its(:email) { should match /email\d+@admin.com/ }
    
    it { should be_valid }
  end
  
  describe "validates" do
    subject { Factory(:admin) }
    
    it { should have_many :mail_logs }
    
    [:email, :password, :password_confirmation, :remember_me].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    # Devise checks presence/uniqueness/format of email, presence/length of password
  end
  
end

# == Schema Information
#
# Table name: admins
#
#  id                   :integer         not null, primary key
#  email                :string(255)     default(""), not null
#  encrypted_password   :string(128)     default(""), not null
#  password_salt        :string(255)     default(""), not null
#  reset_password_token :string(255)
#  remember_token       :string(255)
#  remember_created_at  :datetime
#  sign_in_count        :integer         default(0)
#  current_sign_in_at   :datetime
#  last_sign_in_at      :datetime
#  current_sign_in_ip   :string(255)
#  last_sign_in_ip      :string(255)
#  failed_attempts      :integer         default(0)
#  locked_at            :datetime
#  invitation_token     :string(20)
#  invitation_sent_at   :datetime
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_invitation_token      (invitation_token)
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#

