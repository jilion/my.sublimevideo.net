# coding: utf-8
require 'spec_helper'

describe HostnameUniquenessValidator do
  set(:existing_site) { Factory(:site) }
  
  context "on create" do
    it "should scope by user" do
      site = Factory.build(:site, :user => existing_site.user)
      validate_hostname_uniqueness(site, :hostname, existing_site.hostname)
      site.errors[:hostname].size.should == 1
    end
    
    it "should not add an error if the hostname is blank" do
      site = Factory.build(:site)
      validate_hostname_uniqueness(site, :hostname, nil)
      site.errors[:hostname].size.should == 0
    end
    
    it "should allow 2 users to register the same hostname" do
      site = Factory.build(:site, :user => Factory(:user))
      validate_hostname_uniqueness(site, :hostname, existing_site.hostname)
      site.errors[:hostname].size.should == 0
    end
    
    it "should ignore archived sites" do
      VoxcastCDN.stub(:purge)
      existing_site.archive
      site = Factory.build(:site, :user => existing_site.user)
      validate_hostname_uniqueness(site, :hostname, existing_site.hostname)
      site.errors[:hostname].size.should == 0
    end
  end
  
  context "on update" do
    subject { Factory(:site, :user => existing_site.user).tap { |s| s.update_attribute(:cdn_up_to_date, true) } }
    
    it "should scope by user" do
      validate_hostname_uniqueness(subject, :hostname, existing_site.hostname)
      subject.errors[:hostname].size.should == 1
    end
    
    it "should not add an error if the hostname is blank" do
      validate_hostname_uniqueness(subject, :hostname, nil)
      subject.errors[:hostname].size.should == 0
    end
    
    it "should allow 2 users to register the same hostname" do
      site = Factory(:site, :user => Factory(:user))
      validate_hostname_uniqueness(site, :hostname, existing_site.hostname)
      site.errors[:hostname].size.should == 0
    end
    
    it "should ignore archived sites" do
      VoxcastCDN.stub(:purge)
      existing_site.archive
      existing_site.should be_archived
      validate_hostname_uniqueness(subject, :hostname, existing_site.hostname)
      subject.errors[:hostname].size.should == 0
    end
  end
end

def validate_hostname_uniqueness(record, attribute, value)
  HostnameUniquenessValidator.new(:attributes => attribute).validate_each(record, attribute, value)
end