# == Schema Information
#
# Table name: sites
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  hostname      :string(255)
#  dev_hostnames :string(255)
#  token         :string(255)
#  state         :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe Site do
  before(:each) do
    @valid_attributes = {
      :hostname => "MyString",
      :dev_hostnames => "MyString",
      :token => "MyString",
      :state => "MyString"
    }
  end

  it "should create a new instance given valid attributes" do
    Site.create!(@valid_attributes)
  end
end
