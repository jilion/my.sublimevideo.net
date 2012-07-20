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
#  id                    :integer          not null, primary key
#  type                  :string(20)
#  user_id               :integer
#  client_application_id :integer
#  token                 :string(40)
#  secret                :string(40)
#  callback_url          :string(255)
#  verifier              :string(20)
#  scope                 :string(255)
#  authorized_at         :datetime
#  invalidated_at        :datetime
#  valid_to              :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

