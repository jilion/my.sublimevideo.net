# coding: utf-8
require 'spec_helper'

describe ExtraHostnamesValidator do
  let(:site) { Site.new }

  describe "valid extra hostnames" do
    it "should not add an error" do
      validate_extra_hostnames(site, :extra_hostnames, 'blogspot.com, jilion.org')
      site.errors[:extra_hostnames].should be_empty
    end
  end

  describe "extra hostnames that include wildcard" do
    it "should add an error" do
      validate_extra_hostnames(site, :extra_hostnames, 'jilion.org, *.jilion.org')
      site.errors[:extra_hostnames].should have(1).item
    end
  end

  describe "invalid extra hostnames" do
    it "should add an error" do
      validate_extra_hostnames(site, :extra_hostnames, 'google.local, localhost')
      site.errors[:extra_hostnames].should have(1).item
    end
  end

  describe "duplicated extra hostnames" do
    it "should add an error" do
      validate_extra_hostnames(site, :extra_hostnames, 'jilion.org, jilion.org')
      site.errors[:extra_hostnames].should have(1).item
    end
  end

  describe "extra hostnames that include hostname" do
    it "should add an error" do
      site.update_attribute(:hostname, 'jilion.org')
      validate_extra_hostnames(site, :extra_hostnames, 'jilion.org')
      site.errors[:extra_hostnames].should have(1).item
    end
  end

end

def validate_extra_hostnames(record, attribute, value)
  ExtraHostnamesValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
