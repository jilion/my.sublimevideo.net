# coding: utf-8
require 'spec_helper'

describe ProductionHostnameValidator do
  subject { Spec::Support::Enterprise.new }
  
  describe "invalid hostnames" do
    %w[http://localhost école école.fr üpper.de localhost 123.123.123].each do |hostname|
      it "should add an error to a record if hostname is #{hostname}" do
        validates(subject, :hostnames, hostname)
        subject.errors[:hostnames].should == ["is invalid"]
      end
    end
  end
  
  describe "valid hostnames" do
    %w[ftp://asdasd.com asdasd.com 124.123.151.123 http://aasds.com www.youtube.com?v=31231 127.0.0.1].each do |hostname|
      it "should not add an error to a record if hostname is #{hostname}" do
        validates(subject, :hostnames, hostname)
        subject.errors[:hostnames].should == []
      end
    end
  end
  
end

def validator(attributes)
  @validator ||= ProductionHostnameValidator.new(:attributes => attributes)
end

def validates(record, attribute, value)
  validator(attribute).validate_each(record, attribute, value)
end