require 'spec_helper'

describe ApiToken do
  
  context "Factory" do
    before(:all) { @api_token = Factory(:api_token) }
    subject { @api_token }

    its(:user)                 { should be_present }
    its(:authentication_token) { should be_present }

    it { should be_valid }
  end # Factory

  describe "Associations" do
    before(:all) { @api_token = Factory(:api_token) }
    subject { @api_token }

    it { should belong_to :user }
  end # Associations

  describe "Validations" do
    it { should validate_presence_of(:user_id) }
  end # Validations
  
end

# == Schema Information
#
# Table name: api_tokens
#
#  id                   :integer         not null, primary key
#  user_id              :integer
#  sign_in_count        :integer         default(0)
#  current_sign_in_at   :datetime
#  last_sign_in_at      :datetime
#  current_sign_in_ip   :string(255)
#  last_sign_in_ip      :string(255)
#  authentication_token :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_api_tokens_on_authentication_token  (authentication_token) UNIQUE
#

