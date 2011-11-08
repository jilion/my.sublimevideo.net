# coding: utf-8
require 'spec_helper'

describe HostnameValidator do
  subject { Factory.build(:new_site) }
  
  describe "valid hostname" do
    it "should not add an error" do
      validate_hostname(subject, :hostname, 'école.fr')
      subject.errors[:hostname].size.should == 0
    end
  end
  
  describe "hostname that include wildcard" do
    it "should add an error" do
      validate_hostname(subject, :hostname, '*.google.com')
      subject.errors[:hostname].size.should == 1
    end
  end
  
  describe "invalid hostname" do
    it "should add an error" do
      validate_hostname(subject, :hostname, '123.123.123')
      subject.errors[:hostname].size.should == 1
    end
  end
  
end

def validate_hostname(record, attribute, value)
  HostnameValidator.new(:attributes => attribute).validate_each(record, attribute, value)
end