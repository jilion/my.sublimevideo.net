require 'spec_helper'

describe OauthToken do

  context "Factory" do
    subject { create(:oauth_token) }

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

    describe '#verifier' do
      subject { super().verifier }
      it           { should be_nil }
    end

    it { should be_valid }
    it { should_not be_authorized }
    it { should_not be_invalidated }
  end

  describe "Associations" do
    subject { create(:oauth_token) }

    it { should belong_to :user }
    it { should belong_to :client_application }
  end

  describe "Validations" do
    subject { create(:oauth_token) }

    it { should validate_presence_of(:client_application) }
    it { should validate_presence_of(:token) }
  end

  describe "Scopes" do
    before do
      @user = create(:user)
      @new_token         = create(:oauth_token, user: @user, authorized_at: nil, invalidated_at: nil)
      @authorized_token  = create(:oauth_token, user: @user, authorized_at: Time.now.utc, invalidated_at: nil)
      @invalidated_token = create(:oauth_token, user: @user, authorized_at: Time.now.utc, invalidated_at: Time.now.utc)
    end

    describe ".valid" do
      specify { expect(OauthToken.valid.map(&:id)).to eql [@authorized_token.id] }
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

