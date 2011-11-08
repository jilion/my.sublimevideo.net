require 'spec_helper'

describe PlansHelper do

  describe ".plan_change_type" do
    before(:all) do
      @site_in_trial      = Factory.create(:site)
      @site_not_in_trial  = Factory.create(:site_not_in_trial)
      @paid_plan_monthly  = Factory.create(:plan, cycle: "month", price: 1000)
      @paid_plan_monthly2 = Factory.create(:plan, cycle: "month", price: 2000)
      @paid_plan_yearly   = Factory.create(:plan, cycle: "year", price: 10000)
      @paid_plan_yearly2  = Factory.create(:plan, cycle: "year", price: 20000)
    end

    it { helper.plan_change_type(@site_in_trial, @paid_plan_monthly, @paid_plan_monthly).should  be_nil }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_monthly, @paid_plan_yearly).should   eql "in_trial_update" }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_yearly, @paid_plan_yearly2).should   eql "in_trial_update" }
    it { helper.plan_change_type(@site_in_trial, @free_plan, @paid_plan_monthly).should          eql "in_trial_update" }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_yearly, @paid_plan_monthly).should   eql "in_trial_update" }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_yearly2, @paid_plan_monthly).should  eql "in_trial_update" }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_monthly2, @paid_plan_monthly).should eql "in_trial_update" }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_yearly, @paid_plan_monthly2).should  eql "in_trial_update" }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_yearly, @free_plan).should           eql "in_trial_update_to_free" }
    it { helper.plan_change_type(@site_in_trial, @paid_plan_monthly, @free_plan).should          eql "in_trial_update_to_free" }

    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly, @paid_plan_monthly).should  be_nil }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly, @paid_plan_yearly).should   eql "upgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @paid_plan_yearly2).should   eql "upgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @free_plan, @paid_plan_monthly).should          eql "upgrade_from_free" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @paid_plan_monthly).should   eql "delayed_change" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly2, @paid_plan_monthly).should  eql "delayed_downgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly2, @paid_plan_monthly).should eql "delayed_downgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @paid_plan_monthly2).should  eql "delayed_upgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @free_plan).should           eql "delayed_downgrade_to_free" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly, @free_plan).should          eql "delayed_downgrade_to_free" }
  end

end
