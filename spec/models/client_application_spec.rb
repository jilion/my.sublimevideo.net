require 'spec_helper'

describe ClientApplication do
  let(:application) { create(:client_application) }

  it "should be valid" do
    application.should be_valid
  end

  it "should not have errors" do
    application.errors.full_messages.should be_empty
  end

  it "should have key and secret" do
    application.key.should_not be_nil
    application.secret.should_not be_nil
  end

  it "should have credentials" do
    application.credentials.should_not be_nil
    application.credentials.key.should eql application.key
    application.credentials.secret.should eql application.secret
  end

end

# == Schema Information
#
# Table name: client_applications
#
#  callback_url :string(255)
#  created_at   :datetime
#  id           :integer          not null, primary key
#  key          :string(40)
#  name         :string(255)
#  secret       :string(40)
#  support_url  :string(255)
#  updated_at   :datetime
#  url          :string(255)
#  user_id      :integer
#
# Indexes
#
#  index_client_applications_on_key  (key) UNIQUE
#

