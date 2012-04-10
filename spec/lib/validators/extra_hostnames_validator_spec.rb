# coding: utf-8
require 'spec_helper'

describe ExtraHostnamesValidator do
  subject { build(:new_site) }

  describe "valid extra hostnames" do
    it "should not add an error" do
      validate_extra_hostnames(subject, :extra_hostnames, 'blogspot.com, jilion.org')
      subject.errors[:extra_hostnames].should be_empty
    end
  end

  describe "extra hostnames that include wildcard" do
    it "should add an error" do
      validate_extra_hostnames(subject, :extra_hostnames, 'jilion.org, *.jilion.org')
      subject.errors[:extra_hostnames].should have(1).item
    end
  end

  describe "invalid extra hostnames" do
    it "should add an error" do
      validate_extra_hostnames(subject, :extra_hostnames, 'google.local, localhost')
      subject.errors[:extra_hostnames].should have(1).item
    end
  end

  describe "duplicated extra hostnames" do
    it "should add an error" do
      validate_extra_hostnames(subject, :extra_hostnames, 'jilion.org, jilion.org')
      subject.errors[:extra_hostnames].should have(1).item
    end
  end

  describe "extra hostnames that include hostname" do
    it "should add an error" do
      subject.update_attribute(:hostname, 'jilion.org')
      validate_extra_hostnames(subject, :extra_hostnames, 'jilion.org')
      subject.errors[:extra_hostnames].should have(1).item
    end
  end

end

def validate_extra_hostnames(record, attribute, value)
  ExtraHostnamesValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
