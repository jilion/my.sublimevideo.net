require 'spec_helper'

describe PlansHelper do
  
  describe ".plan_change_type" do
    before(:all) do
      @paid_plan_monthly  = FactoryGirl.create(:plan, cycle: "month", price: 1000)
      @paid_plan_monthly2 = FactoryGirl.create(:plan, cycle: "month", price: 2000)
      @paid_plan_yearly   = FactoryGirl.create(:plan, cycle: "year", price: 10000)
      @paid_plan_yearly2  = FactoryGirl.create(:plan, cycle: "year", price: 20000)
    end
    
    specify { helper.plan_change_type(@paid_plan_monthly, @paid_plan_monthly).should  be_nil }
    specify { helper.plan_change_type(@paid_plan_monthly, @paid_plan_yearly).should   == "upgrade" }
    specify { helper.plan_change_type(@paid_plan_yearly, @paid_plan_yearly2).should   == "upgrade" }
    specify { helper.plan_change_type(@dev_plan, @paid_plan_monthly).should           == "upgrade_from_dev" }
    specify { helper.plan_change_type(@paid_plan_yearly, @paid_plan_monthly).should   == "delayed_change" }
    specify { helper.plan_change_type(@paid_plan_yearly2, @paid_plan_monthly).should  == "delayed_downgrade" }
    specify { helper.plan_change_type(@paid_plan_monthly2, @paid_plan_monthly).should == "delayed_downgrade" }
    specify { helper.plan_change_type(@paid_plan_yearly, @paid_plan_monthly2).should  == "delayed_upgrade" }
    specify { helper.plan_change_type(@paid_plan_yearly, @dev_plan).should            == "delayed_downgrade_to_dev" }
    specify { helper.plan_change_type(@paid_plan_monthly, @dev_plan).should           == "delayed_downgrade_to_dev" }
    
  end
  
end
