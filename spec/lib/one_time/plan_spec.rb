# coding: utf-8
require 'spec_helper'

describe OneTime::Plan do
  
  context "with 1 invited and 1 beta user" do
    it "should only archive invited and not yet registered users" do
      Plan.delete_all
      Plan.all.should be_empty
      described_class.create_plans
      Plan.all.count.should == 11
    end
  end
  
end
