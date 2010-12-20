# coding: utf-8
require 'spec_helper'

describe HostnameUniquenessValidator do
  let(:site) { Factory(:site) }
  
  context "on create" do
    it "should scope by user" do
      site2 = Factory.build(:site, :user => site.user)
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].size.should == 1
    end
    
    it "should not add an error if the hostname is blank" do
      site2 = Factory.build(:site)
      validate_hostname_uniqueness(site2, :hostname, nil)
      site2.errors[:hostname].size.should == 0
    end
    
    it "should allow 2 users to register the same hostname" do
      site2 = Factory.build(:site, :user => Factory(:user))
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].size.should == 0
    end
    
    it "should ignore archived sites" do
      VoxcastCDN.stub(:purge)
      site.archive
      site.should be_archived
      site2 = Factory.build(:site, :user => site.user)
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].size.should == 0
    end
  end
  
  context "on update" do
    subject { Factory(:site, :user => site.user).tap { |s| s.update_attribute(:cdn_up_to_date, true) } }
    
    it "should scope by user" do
      validate_hostname_uniqueness(subject, :hostname, site.hostname)
      subject.errors[:hostname].size.should == 1
    end
    
    it "should not add an error if the hostname is blank" do
      validate_hostname_uniqueness(subject, :hostname, nil)
      subject.errors[:hostname].size.should == 0
    end
    
    it "should allow 2 users to register the same hostname" do
      site2 = Factory(:site, :user => Factory(:user))
      validate_hostname_uniqueness(site2, :hostname, site.hostname)
      site2.errors[:hostname].size.should == 0
    end
    
    it "should ignore archived sites" do
      VoxcastCDN.stub(:purge)
      site.archive
      site.should be_archived
      validate_hostname_uniqueness(subject, :hostname, site.hostname)
      subject.errors[:hostname].size.should == 0
    end
  end
end

def validate_hostname_uniqueness(record, attribute, value)
  HostnameUniquenessValidator.new(:attributes => attribute).validate_each(record, attribute, value)
end