# coding: utf-8
require 'spec_helper'

describe HostnameUniquenessValidator do
  let(:site) { create(:site) }

  context "on create" do
    it "should scope by user" do
      site2 = build(:site, user: site.user)
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].should have(1).item
    end

    it "should not add an error if the hostname is blank" do
      site2 = build(:site)
      validate_hostname_uniqueness(site2, :hostname, nil)
      site2.errors[:hostname].should be_empty
    end

    it "should allow 2 users to register the same hostname" do
      site2 = build(:site, user: create(:user))
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].should be_empty
    end

    it "should ignore archived sites" do
      CDN.stub(:purge)
      site.user.current_password = '123456'
      site.archive
      site.should be_archived
      site2 = build(:site, user: site.user)
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].should be_empty
    end
  end

  context "on update" do
    subject { create(:site, user: site.user) }

    it "should scope by user" do
      validate_hostname_uniqueness(subject, :hostname, site.hostname)
      subject.errors[:hostname].should have(1).item
    end

    it "should not add an error if the hostname is blank" do
      validate_hostname_uniqueness(subject, :hostname, nil)
      subject.errors[:hostname].should be_empty
    end

    it "should allow 2 users to register the same hostname" do
      site2 = create(:site, user: create(:user))
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].should be_empty
    end

    it "should ignore archived sites" do
      CDN.stub(:purge)
      site.user.current_password = '123456'
      site.archive
      site.should be_archived
      validate_hostname_uniqueness(subject, :hostname, site.hostname)
      subject.errors[:hostname].should be_empty
    end
  end
end

def validate_hostname_uniqueness(record, attribute, value)
  HostnameUniquenessValidator.new(attributes: attribute).validate_each(record, attribute, value)
end
