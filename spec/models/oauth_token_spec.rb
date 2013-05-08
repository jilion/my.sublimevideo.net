require 'spec_helper'

describe OauthToken do

  context "Factory" do
    subject { create(:oauth_token) }

    its(:user)               { should be_present }
    its(:client_application) { should be_present }
    its(:token)              { should be_present }
    its(:secret)             { should be_present }
    its(:verifier)           { should be_nil }

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

    [].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

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
      specify { OauthToken.valid.map(&:id).should eql [@authorized_token.id] }
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

