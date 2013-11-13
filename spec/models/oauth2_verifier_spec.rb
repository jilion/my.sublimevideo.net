require 'spec_helper'

describe Oauth2Verifier do

  context "Factory" do
    subject { create(:oauth2_verifier) }

    describe '#user' do
      subject { super().user }
      it               { should be_present }
    end

    describe '#client_application' do
      subject { super().client_application }
      it { should be_present }
    end

    describe '#code' do
      subject { super().code }
      it               { should be_present }
    end

    describe '#token' do
      subject { super().token }
      it              { should be_present }
    end

    describe '#expires_at' do
      subject { super().expires_at }
      it         { should be_present }
    end

    it { should be_valid }
    it { should be_authorized }
    it { should_not be_invalidated }
  end

  describe "exchange for oauth2 token" do
    let(:verifier) { create(:oauth2_verifier) }
    let(:token) { verifier.exchange! }

    it "should invalidate verifier" do
      verifier.exchange!
      expect(verifier).to be_invalidated
    end

    it "should set user on token" do
      expect(token.user).to eql verifier.user
    end

    it "should set client application on token" do
      expect(token.client_application).to eql verifier.client_application
    end

    it "should be authorized" do
      expect(token).to be_authorized
    end

    it "should not be invalidated" do
      expect(token).not_to be_invalidated
    end
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

