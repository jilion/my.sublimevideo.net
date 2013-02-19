# coding: utf-8
require 'spec_helper'

describe HostnameValidator do
  let(:site) { Site.new }

  describe "valid hostname" do
    it "should not add an error" do
      validate_hostname(site, :hostname, 'école.fr')
      site.errors[:hostname].should be_empty
    end
  end

  describe "hostname that include wildcard" do
    it "should add an error" do
      validate_hostname(site, :hostname, '*.google.com')
      site.errors[:hostname].should have(1).item
    end
  end

  describe "invalid hostname" do
    it "should add an error" do
      validate_hostname(site, :hostname, '123.123.123')
      site.errors[:hostname].should have(1).item
    end
  end

end

def validate_hostname(record, attribute, value)
  HostnameValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
