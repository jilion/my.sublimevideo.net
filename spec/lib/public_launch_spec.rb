require 'spec_helper'

describe PublicLaunch do

  its(:beta_transition_ended_on) { should == Date.new(2011, 3, 1) }

  describe ".days_left_before_end_of_beta_transition" do

    it "should return 12" do
      PublicLaunch.stub(:beta_transition_ended_on) { Date.new(2011, 3, 1) }
      Timecop.travel(Date.new(2011, 2, 17))
      PublicLaunch.days_left_before_end_of_beta_transition.should == 12
      Timecop.return
    end
  end
end
