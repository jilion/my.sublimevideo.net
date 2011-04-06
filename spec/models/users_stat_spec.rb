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
    it "should delay itself" do
      UsersStat.should_receive(:delay_create_users_stats)
      UsersStat.create_users_stats
    end

    it "should create users stats for states" do
      user1 = Factory(:user)
      Factory(:site, user: user1, plan_id: @paid_plan.id)
      Factory(:site, user: user1, plan_id: @paid_plan.id)
      user2 = Factory(:user)
      Factory(:site, user: user1, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @dev_plan.id)
      user3 = Factory(:user)
      Factory(:site, user: user3, plan_id: @dev_plan.id)
      user4 = Factory(:user)
      user5 = Factory(:user, :state => 'suspended')
      user6 = Factory(:user, :state => 'archived')

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
  end

end
