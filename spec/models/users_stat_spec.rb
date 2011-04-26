require 'spec_helper'

describe UsersStat do

  describe ".delay_create_users_stats" do
    it "should delay create_users_stats if not already delayed" do
      expect { UsersStat.delay_create_users_stats }.should change(Delayed::Job.where(:handler.matches => '%UsersStat%create_users_stats%'), :count).by(1)
    end

    it "should not delay create_users_stats if already delayed" do
      UsersStat.delay_create_users_stats
      expect { UsersStat.delay_create_users_stats }.should change(Delayed::Job.where(:handler.matches => '%UsersStat%create_users_stats%'), :count).by(0)
    end

    it "should delay create_users_stats for next hour" do
      UsersStat.delay_create_users_stats
      Delayed::Job.last.run_at.should == Time.new.utc.tomorrow.midnight
    end
  end

  describe ".create_users_stats" do
    before(:all) do
      Factory(:site, plan_id: @paid_plan.id) # active & billable

      Factory(:user) # active & not billable
      Factory(:site, plan_id: @dev_plan.id) # active & not billable
      Factory(:site, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @dev_plan.id) # active & not billable

      Factory(:user, state: 'suspended') # suspended
      Factory(:user, state: 'archived') # archived


      # USERS CREATED 1 DAY AGO
      Factory(:user, created_at: 1.day.ago) # active & not billable

      Factory(:user, state: 'archived', created_at: 1.day.ago) # archived
    end

    it "should delay itself" do
      UsersStat.should_receive(:delay_create_users_stats)
      UsersStat.create_users_stats
    end

    it "should create users stats for states" do
      UsersStat.create_users_stats

      UsersStat.count.should == 1
      users_stat = UsersStat.last
      users_stat.states_count.should == {
        "active_and_billable_count"     => 1,
        "active_and_not_billable_count" => 3,
        "suspended_count"               => 1,
        "archived_count"                => 1
      }
    end

    context "giving it a timestamp" do
      it "should create users stats for states" do
        UsersStat.create_users_stats(1.day.ago)

        UsersStat.count.should == 1
        users_stat = UsersStat.last
        users_stat.states_count.should == {
          "active_and_billable_count"     => 0,
          "active_and_not_billable_count" => 1,
          "suspended_count"               => 0,
          "archived_count"                => 1
        }
      end
    end
  end

end
