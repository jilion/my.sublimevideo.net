require 'spec_helper'

describe UsersStat do

  context "Factory build" do
    subject { Factory.build(:users_stat) }

    its(:active_and_billable_count)     { should == 0 }
    its(:active_and_not_billable_count) { should == 0 }
    its(:suspended_count)               { should == 0 }
    its(:archived_count)                { should == 0 }
  end

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
      Delayed::Job.last.run_at.should == Time.now.utc.change(:min => 0) + 1.hour
    end

  end

  describe ".create_users_stats" do

    it "should delay itself" do
      UsersStat.should_receive(:delay_create_users_stats)
      UsersStat.create_users_stats
    end

    it "should create users stats for scope counter" do
      user1 = Factory(:user)
      Factory(:site, :user => user1, :activated_at => Time.utc(2011,1,1))
      user2 = Factory(:user)
      Factory(:site, :user => user2, :activated_at => Time.utc(2011,1,1), :archived_at => Time.utc(2011,1,2))
      user3 = Factory(:user)
      Factory(:site, :user => user3, :activated_at => nil)
      user4 = Factory(:user)
      user5 = Factory(:user, :state => 'suspended')
      user6 = Factory(:user, :state => 'archived')

      UsersStat.create_users_stats

      UsersStat.count.should == 1
      users_stat = UsersStat.last
      users_stat.active_and_billable_count.should     == 1
      users_stat.active_and_not_billable_count.should == 3
      users_stat.suspended_count.should               == 1
      users_stat.archived_count.should                == 1
    end

  end

end
