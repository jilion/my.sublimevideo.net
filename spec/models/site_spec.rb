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