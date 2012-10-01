# coding: utf-8
require 'spec_helper'

describe DevHostnamesValidator do
  subject { build(:site) }

  describe "valid dev hostnames" do
    it "should not add an error" do
      validate_dev_hostnames(subject, :dev_hostnames, 'localhost, 127.0.0.1')
      subject.errors[:dev_hostnames].should be_empty
    end
  end

  describe "dev hostnames that include wildcard" do
    it "should add an error" do
      validate_dev_hostnames(subject, :dev_hostnames, 'localhost, *.local')
      subject.errors[:dev_hostnames].should have(1).item
    end
  end

  describe "invalid dev hostnames" do
    it "should add an error" do
      validate_dev_hostnames(subject, :dev_hostnames, '124.123.151.123, localhost')
      subject.errors[:dev_hostnames].should have(1).item
    end
  end

  describe "duplicated dev hostnames" do
    it "should add an error" do
      validate_dev_hostnames(subject, :dev_hostnames, 'localhost, localhost')
      subject.errors[:dev_hostnames].should have(1).item
    end
  end

  describe "dev hostnames that include hostname" do
    it "should add an error" do
      subject.update_attribute(:hostname, 'remy.local')
      validate_dev_hostnames(subject, :dev_hostnames, 'remy.local')
      subject.errors[:dev_hostnames].should have(1).item
    end
  end

end

def validate_dev_hostnames(record, attribute, value)
  DevHostnamesValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
