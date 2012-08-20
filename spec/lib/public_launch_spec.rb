require 'fast_spec_helper'
require 'timecop'
require 'active_support/core_ext'
require File.expand_path('lib/public_launch')

describe PublicLaunch do

  it "returns beta_transition_started_on from yaml file" do
    PublicLaunch.beta_transition_started_on.should == Date.new(2011, 3, 29)
  end

  it "should return the beta_transition_ended_on" do
    PublicLaunch.beta_transition_ended_on.should == Time.utc(2011, 4, 16, 12)
  end

  it "should return the v2_started_on" do
    PublicLaunch.v2_started_on.should == Time.utc(2011, 10, 1)
  end

  describe ".days_left_before_end_of_beta_transition" do
    it "should return days to end of beta" do
      Timecop.travel(Time.utc(2011, 4, 10, 10)) do
        PublicLaunch.days_left_before_end_of_beta_transition.should == 6
      end
    end

    it "should return days to end of beta" do
      Timecop.travel(Time.utc(2011, 4, 10, 15)) do
        PublicLaunch.days_left_before_end_of_beta_transition.should == 5
      end
    end
  end

  describe ".hours_left_before_end_of_beta_transition" do
    it "should return days to end of beta" do
      Timecop.travel(Time.utc(2011, 4, 14, 10, 1)) do
        PublicLaunch.hours_left_before_end_of_beta_transition.should == 49
      end
    end

    it "should return days to end of beta" do
      Timecop.travel(Time.utc(2011, 4, 14, 15, 1)) do
        PublicLaunch.hours_left_before_end_of_beta_transition.should == 44
      end
    end
  end

end
