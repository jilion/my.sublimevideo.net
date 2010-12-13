require 'spec_helper'

describe TimeUtil do
  
  describe ".full_month" do
    specify { TimeUtil.full_month.should == [Time.now.utc.beginning_of_month, Time.now.utc.end_of_month] }
    specify { TimeUtil.full_month(Time.utc(2010,2,23)).should == [Time.utc(2010,2).beginning_of_month, Time.utc(2010,2).end_of_month] }
    specify { TimeUtil.current_month.should == TimeUtil.full_month }
  end
  
  describe ".prev_full_month" do
    specify { TimeUtil.prev_full_month.should == [Time.now.utc.prev_month.beginning_of_month, Time.now.utc.prev_month.end_of_month] }
    specify { TimeUtil.prev_full_month(Time.utc(2010,2,23)).should == [Time.utc(2010,1).beginning_of_month, Time.utc(2010,1).end_of_month] }
  end
  
  describe ".next_full_month" do
    specify { TimeUtil.next_full_month.should == [Time.now.utc.next_month.beginning_of_month, Time.now.utc.next_month.end_of_month] }
    specify { TimeUtil.next_full_month(Time.utc(2010,2,23)).should == [Time.utc(2010,3).beginning_of_month, Time.utc(2010,3).end_of_month] }
  end
  
end