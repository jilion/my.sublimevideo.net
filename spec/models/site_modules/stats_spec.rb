require 'spec_helper'

describe SiteModules::Stats do

  describe "#stats_retention_days" do

    it "egals paid plan stats_retention_days" do
      site = Factory.build(:site, plan_id: @paid_plan.id)
      site.stats_retention_days.should eql 365
    end

    it "egals paid plan stats_retention_days (unlimited)" do
      paid_plan = Factory.create(:plan, stats_retention_days: nil)
      site = Factory.build(:site, plan_id: paid_plan.id)
      site.stats_retention_days.should eql nil
    end

    it "egals free plan stats_retention_days when trial mode isn't started" do
      site = Factory.build(:site, plan_id: @free_plan.id)
      site.stats_retention_days.should eql 0
    end

    it "egals 365 when trial mode is started" do
      site = Factory.build(:site, plan_id: @free_plan.id)
      site.stats_trial_started_at = 1.day.ago
      site.stats_retention_days.should eql 365
    end

    it "egals free plan stats_retention_days when trial mode has been already used" do
      site = Factory.build(:site, plan_id: @free_plan.id)
      site.stats_trial_started_at = 60.days.ago
      site.stats_retention_days.should eql 0
    end
  end

end
