# coding: utf-8
require 'spec_helper'

describe HostnameValidator do
  subject { RSpec::Support::Enterprise.new }
  
  # describe "invalid hostname" do
  #   %w[http://localhost école école.fr üpper.de localhost 123.123.123].each do |hostname|
  #     it "should add an error to a record if hostname is #{hostname}" do
  #       HostnameValidator.new(:attributes => :hostname).validate_each(subject, :hostname, hostname)
  #       subject.errors[:hostname].should == ["is invalid"]
  #     end
  #   end
  # end
  # 
  # describe "valid hostname" do
  #   %w[ftp://asdasd.com asdasd.com 124.123.151.123 http://aasds.com www.youtube.com?v=31231 127.0.0.1].each do |hostname|
  #     it "should not add an error to a record if hostname is #{hostname}" do
  #       HostnameValidator.new(:attributes => :hostname).validate_each(subject, :hostname, hostname)
  #       subject.errors[:hostname].should == []
  #     end
  #   end
  # end
  
end