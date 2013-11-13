require 'spec_helper'

describe Oauth2Token do

  context "Factory" do
    subject { create(:oauth2_token) }

    describe '#user' do
      subject { super().user }
      it               { should be_present }
    end

    describe '#client_application' do
      subject { super().client_application }
      it { should be_present }
    end

    describe '#token' do
      subject { super().token }
      it              { should be_present }
    end

    describe '#secret' do
      subject { super().secret }
      it             { should be_present }
    end

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
#  created_at            :datetime
#  expires_at            :datetime
#  id                    :integer          not null, primary key
#  invalidated_at        :datetime
#  scope                 :string(255)
#  secret                :string(40)
#  token                 :string(40)
#  type                  :string(20)
#  updated_at            :datetime
#  user_id               :integer
#  verifier              :string(20)
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

