require 'spec_helper'

describe Oauth2Token do

  context "Factory" do
    subject { create(:oauth2_token) }

    its(:user)               { should be_present }
    its(:client_application) { should be_present }
    its(:token)              { should be_present }
    its(:secret)             { should be_present }

    it { should be_valid }
    it { should be_authorized }
    it { should_not be_invalidated }
  end

end

# == Schema Information
#
# Table name: oauth_tokens
#
#  authorized_at         :datetime
#  callback_url          :string(255)
#  client_application_id :integer
#  created_at            :datetime         not null
#  expires_at            :datetime
#  id                    :integer          not null, primary key
#  invalidated_at        :datetime
#  scope                 :string(255)
#  secret                :string(40)
#  token                 :string(40)
#  type                  :string(20)
#  updated_at            :datetime         not null
#  user_id               :integer
#  verifier              :string(20)
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

