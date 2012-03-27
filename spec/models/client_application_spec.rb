require 'spec_helper'

describe ClientApplication do
  before(:all) do
    @application = create(:client_application)
  end
  subject { @application.reload }

  it "should be valid" do
    @application.should be_valid
  end

  it "should not have errors" do
    @application.errors.full_messages.should be_empty
  end

  it "should have key and secret" do
    @application.key.should_not be_nil
    @application.secret.should_not be_nil
  end

  it "should have credentials" do
    @application.credentials.should_not be_nil
    @application.credentials.key.should eql @application.key
    @application.credentials.secret.should eql @application.secret
  end

end



# == Schema Information
#
# Table name: client_applications
#
#  id           :integer         not null, primary key
#  user_id      :integer
#  name         :string(255)
#  url          :string(255)
#  support_url  :string(255)
#  callback_url :string(255)
#  key          :string(40)
#  secret       :string(40)
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_client_applications_on_key  (key) UNIQUE
#

