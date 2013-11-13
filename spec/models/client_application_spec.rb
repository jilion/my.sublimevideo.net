require 'spec_helper'

describe ClientApplication do
  let(:application) { create(:client_application) }

  it "should be valid" do
    expect(application).to be_valid
  end

  it "should not have errors" do
    expect(application.errors.full_messages).to be_empty
  end

  it "should have key and secret" do
    expect(application.key).not_to be_nil
    expect(application.secret).not_to be_nil
  end

  it "should have credentials" do
    expect(application.credentials).not_to be_nil
    expect(application.credentials.key).to eql application.key
    expect(application.credentials.secret).to eql application.secret
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

