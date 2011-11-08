require 'spec_helper'

describe OauthToken do

  context "Factory" do
    before(:all) { @token = Factory.create(:oauth_token) }
    subject { @token }

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
    before(:all) { @token = Factory.create(:oauth_token) }
    subject { @token }

    it { should belong_to :user }
    it { should belong_to :client_application }
  end

  describe "Validations" do
    before(:all) { @token = Factory.create(:oauth_token) }
    subject { @token.reload }

    [].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:client_application) }
    it { should validate_presence_of(:token) }
  end

  describe "Scopes" do
    before(:all) do
      User.delete_all
      @user = Factory.create(:user)
      @new_token         = Factory.create(:oauth_token, user: @user, authorized_at: nil, invalidated_at: nil)
      @authorized_token  = Factory.create(:oauth_token, user: @user, authorized_at: Time.now.utc, invalidated_at: nil)
      @invalidated_token = Factory.create(:oauth_token, user: @user, authorized_at: Time.now.utc, invalidated_at: Time.now.utc)
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
#  id                    :integer         not null, primary key
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
#  created_at            :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_oauth_tokens_on_token  (token) UNIQUE
#

