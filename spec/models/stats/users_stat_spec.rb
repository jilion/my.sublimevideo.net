require 'spec_helper'

describe Stats::UsersStat do

  describe ".delay_create_users_stats" do
    it "should delay create_users_stats if not already delayed" do
      expect { described_class.delay_create_users_stats }.should change(Delayed::Job.where(:handler.matches => '%Stats::UsersStat%create_users_stats%'), :count).by(1)
    end

    it "should not delay create_users_stats if already delayed" do
      described_class.delay_create_users_stats
      expect { described_class.delay_create_users_stats }.should change(Delayed::Job.where(:handler.matches => '%Stats::UsersStat%create_users_stats%'), :count).by(0)
    end

    it "should delay create_users_stats for next hour" do
      described_class.delay_create_users_stats
      Delayed::Job.last.run_at.should == Time.new.utc.tomorrow.midnight
    end
  end

  describe ".create_users_stats" do
    before(:all) do
      Factory.create(:user) # free (no sites)
      Factory.create(:site, plan_id: @free_plan.id) # free (only free sites)
      Factory.create(:site, plan_id: @paid_plan.id) # free (site is in trial)

      Factory.create(:site_not_in_trial, plan_id: @paid_plan.id) # paying
      Factory.create(:site_not_in_trial, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @free_plan.id) # paying with next cycle plan

      Factory.create(:user, state: 'suspended') # suspended
      Factory.create(:user, state: 'archived') # archived
    end

    it "should delay itself" do
      described_class.should_receive(:delay_create_users_stats)
      described_class.create_users_stats
    end

    it "should create users stats for states" do
      described_class.create_users_stats

      described_class.count.should == 1
      users_stat = described_class.last
      users_stat.fr.should eq 3
      users_stat.pa.should eq 2
      users_stat.su.should eq 1
      users_stat.ar.should eq 1
    end
  end

  describe ".json" do
    before(:each) do
      Factory.create(:users_stat)
    end

    describe "set the id as the 'd' field as an integer" do
      subject { JSON.parse(described_class.json) }

      its(:size) { should eql(1) }
      it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    end
  end

end
