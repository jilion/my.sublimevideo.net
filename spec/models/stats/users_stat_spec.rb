require 'spec_helper'

describe Stats::UsersStat, :plans do

  pending ".create_stats" do
    before do
      create(:user) # free (no sites)
      create(:site, plan_id: @free_plan.id) # free (only free sites)
      create(:site, plan_id: @trial_plan.id) # free (site is in trial)

      create(:site, plan_id: @paid_plan.id) # paying
      create(:site, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @free_plan.id) # paying with next cycle plan

      create(:user, state: 'suspended') # suspended
      create(:user, state: 'archived') # archived
    end

    it "should create users stats for states" do
      described_class.create_stats

      described_class.count.should eq 1
      users_stat = described_class.last
      users_stat.fr.should eq 3
      users_stat.pa.should eq 2
      users_stat.su.should eq 1
      users_stat.ar.should eq 1
    end
  end

  describe ".json" do
    before do
      create(:users_stat, d: Time.now.utc.midnight)
    end

    describe "set the id as the 'd' field as an integer" do
      subject { JSON.parse(described_class.json) }

      its(:size) { should eq 1 }
      it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    end
  end

end
