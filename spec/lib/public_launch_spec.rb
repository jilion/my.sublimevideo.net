require 'spec_helper'

describe PublicLaunch do

  its(:beta_transition_ended_on) { should == Date.new(2011, 4, 16) }

  describe ".days_left_before_end_of_beta_transition" do
    it "should return days to end of beta" do
      Timecop.travel(Date.new(2011, 4, 10))
      PublicLaunch.days_left_before_end_of_beta_transition.should == 6
      Timecop.return
    end
  end

end
