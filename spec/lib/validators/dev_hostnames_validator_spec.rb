# coding: utf-8
require 'spec_helper'

describe DevHostnamesValidator do
  subject { RSpec::Support::Enterprise.new }
  
  # describe "invalid hostnames" do
  #   ['123.123.123,localhost', ', ,123.123.123,'].each do |hostnames|
  #     it "should add an error to a record if hostnames are #{hostnames}" do
  #       DevHostnamesValidator.new(:attributes => :hostnames).validate_each(subject, :hostnames, hostnames)
  #       subject.errors[:hostnames].should == ["is invalid"]
  #     end
  #   end
  # end
  # 
  # describe "valid hostnames" do
  #   ['localhost', ', ,', 'localhost,, , 127.0.0.1'].each do |hostnames|
  #     it "should not add an error to a record if hostnames are #{hostnames}" do
  #       subject.errors[:hostnames].should == []
  #       DevHostnamesValidator.new(:attributes => :hostnames).validate_each(subject, :hostnames, hostnames)
  #       subject.errors[:hostnames].should == []
  #     end
  #   end
  # end
  
end