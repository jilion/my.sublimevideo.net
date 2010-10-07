# coding: utf-8
require 'spec_helper'

describe HostnameUniquenessValidator do
  subject { Factory.build(:site, :hostname => "google.com", :user => Factory(:user)) }
  
  describe "non-unique hostname for the user among its non-archived hostnames" do
    it "should add an error to the record" do
      Factory(:site, :hostname => subject.hostname, :user => subject.user)
      validates(subject, :hostname, subject.hostname)
      
      subject.should_not be_valid
      subject.errors[:hostname].should == ["has already been taken"]
    end
  end
  
  describe "unique hostnames for the user among its non-archived hostnames" do
    it "should not add an error if hostname" do
      validates(subject, :hostnames, subject.hostname)
      
      subject.should be_valid
      subject.errors[:hostnames].should == []
    end
    
    it "should not add an error if another site has the same hostname and is archived" do
      archived_site = Factory(:site, :hostname => subject.hostname, :user => subject.user)
      archived_site.archive
      validates(subject, :hostnames, subject.hostname)
      
      archived_site.should be_archived
      subject.should be_valid
      subject.errors[:hostnames].should == []
    end
  end
  
end

def validator(attributes)
  @validator ||= HostnameUniquenessValidator.new(:attributes => attributes)
end

def validates(record, attribute, value)
  validator(attribute).validate_each(record, attribute, value)
end