require 'spec_helper'

describe PlansHelper do

  describe ".plan_change_type", :plans do
    before(:all) do
      @site_in_trial      = create(:site, plan_id: @trial_plan.id)
      @site_not_in_trial  = create(:site_not_in_trial)
      @paid_plan_monthly  = create(:plan, cycle: "month", price: 1000)
      @paid_plan_monthly2 = create(:plan, cycle: "month", price: 2000)
      @paid_plan_yearly   = create(:plan, cycle: "year", price: 10000)
      @paid_plan_yearly2  = create(:plan, cycle: "year", price: 20000)
    end
    after(:all) { DatabaseCleaner.clean_with(:truncation) }

    it { helper.plan_change_type(@site_in_trial, @trial_plan, @paid_plan_yearly).should   eq "in_trial_upgrade" }
    it { helper.plan_change_type(@site_in_trial, @trial_plan, @paid_plan_yearly2).should  eq "in_trial_upgrade" }
    it { helper.plan_change_type(@site_in_trial, @trial_plan, @paid_plan_monthly).should  eq "in_trial_upgrade" }
    it { helper.plan_change_type(@site_in_trial, @trial_plan, @paid_plan_monthly2).should eq "in_trial_upgrade" }
    it { helper.plan_change_type(@site_in_trial, @trial_plan, @free_plan).should          eq "in_trial_downgrade_to_free" }

    it { helper.plan_change_type(@site_not_in_trial, @free_plan, @paid_plan_monthly).should          eq "upgrade_from_free" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly, @free_plan).should          eq "delayed_downgrade_to_free" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly, @paid_plan_monthly).should  be_nil }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly, @paid_plan_yearly).should   eq "upgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_monthly2, @paid_plan_monthly).should eq "delayed_downgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @free_plan).should           eq "delayed_downgrade_to_free" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @paid_plan_monthly2).should  eq "delayed_upgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @paid_plan_yearly2).should   eq "upgrade" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly, @paid_plan_monthly).should   eq "delayed_change" }
    it { helper.plan_change_type(@site_not_in_trial, @paid_plan_yearly2, @paid_plan_monthly).should  eq "delayed_downgrade" }
  end

end
