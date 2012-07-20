require 'spec_helper'

describe Oauth2Verifier do

  context "Factory" do
    subject { create(:oauth2_verifier) }

    its(:user)               { should be_present }
    its(:client_application) { should be_present }
    its(:code)               { should be_present }
    its(:token)              { should be_present }
    its(:valid_to)           { should be_present }

    it { should be_valid }
    it { should be_authorized }
    it { should_not be_invalidated }
  end

  describe "exchange for oauth2 token" do
    let(:verifier) { create(:oauth2_verifier) }
    let(:token) { verifier.exchange! }

    it "should invalidate verifier" do
      verifier.exchange!
      verifier.should be_invalidated
    end

    it "should set user on token" do
      token.user.should eql verifier.user
    end

    it "should set client application on token" do
      token.client_application.should eql verifier.client_application
    end

    it "should be authorized" do
      token.should be_authorized
    end

    it "should not be invalidated" do
      token.should_not be_invalidated
    end
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

