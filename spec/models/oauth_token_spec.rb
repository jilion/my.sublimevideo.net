require 'spec_helper'

describe RequestToken do

  before(:each) do
    @token = Factory(:request_token)
    @user  = Factory(:user)
  end

  it "should be valid" do
    @token.should be_valid
  end

  it "should not have errors" do
    @token.errors.should be_empty
  end

  it "should have a token" do
    @token.token.should_not be_nil
  end

  it "should have a secret" do
    @token.secret.should_not be_nil
  end

  it "should not be authorized" do
    @token.should_not be_authorized
  end

  it "should not be invalidated" do
    @token.should_not be_invalidated
  end

  it "should not have a verifier" do
    @token.verifier.should be_nil
  end

  it "should not be oob" do
    @token.should_not be_oob
  end

end

# == Schema Information
#
# Table name: oauth_tokens
#
#  id                    :integer         not null, primary key
#  user_id               :integer
#  type                  :string(20)
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

