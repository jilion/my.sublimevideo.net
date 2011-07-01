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
#  id         :integer         not null, primary key
#  user_id    :integer
#  public_key :string(255)
#  secret_key :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_api_tokens_on_public_key  (public_key) UNIQUE
#  index_api_tokens_on_secret_key  (secret_key) UNIQUE
#

