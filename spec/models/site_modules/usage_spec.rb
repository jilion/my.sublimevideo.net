require 'spec_helper'

describe SiteModules::Usage do

  describe "#update_last_30_days_counters" do
    before(:all) do
      @site = FactoryGirl.create(:site, last_30_days_main_video_views: 1)
      FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2010,12,31).midnight,
        main_player_hits:  6,   main_player_hits_cached:  4,
        extra_player_hits: 5,   extra_player_hits_cached: 5,
        dev_player_hits:   4,   dev_player_hits_cached:   6
      )
      FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1).midnight,
        main_player_hits:  6,   main_player_hits_cached:  4,
        extra_player_hits: 5,   extra_player_hits_cached: 5,
        dev_player_hits:   4,   dev_player_hits_cached:   6
      )
      FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,30).midnight,
        main_player_hits:  6,   main_player_hits_cached:  4,
        extra_player_hits: 5,   extra_player_hits_cached: 5,
        dev_player_hits:   4,   dev_player_hits_cached:   6
      )
      FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,31).midnight,
        main_player_hits:  6,   main_player_hits_cached:  4,
        extra_player_hits: 5,   extra_player_hits_cached: 5,
        dev_player_hits:   4,   dev_player_hits_cached:   6
      )
    end

    it "should update counters of non-archived sites from last 30 days site_usages" do
      Timecop.travel(Time.utc(2011,1,31, 12)) do
        @site.update_last_30_days_counters
        @site.last_30_days_main_video_views.should  == 20
        @site.last_30_days_extra_video_views.should == 20
        @site.last_30_days_dev_video_views.should   == 20
      end
    end
  end

  describe "#billable_usages" do
    before(:all) { Timecop.travel(15.days.ago) { @site = FactoryGirl.create(:site_not_in_trial) } }
    before(:each) do
      @site.unmemoize_all
      FactoryGirl.create(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 4)
      FactoryGirl.create(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 3)
      FactoryGirl.create(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 2)
      FactoryGirl.create(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 0)
      FactoryGirl.create(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 1)
      FactoryGirl.create(:site_usage, site_id: @site.id, day: 6.days.ago, main_player_hits: 0)
      FactoryGirl.create(:site_usage, site_id: @site.id, day: 7.days.ago, main_player_hits: 0)
    end

    describe "#current_monthly_billable_usages" do
      specify { @site.current_monthly_billable_usages.should == [0, 0, 1, 0, 2, 3, 4] }
    end

    it "last_30_days_billable_usages should skip first zeros" do
      @site.last_30_days_billable_usages.should == [1, 0, 2, 3, 4]
    end
  end

  describe "#current_monthly_billable_usages.sum & #current_percentage_of_plan_used" do
    before(:all) { @site = FactoryGirl.create(:site) }
    before(:each) do
      FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,30),
        main_player_hits:  1, main_player_hits_cached:  2,
        extra_player_hits: 3, extra_player_hits_cached: 4,
        dev_player_hits:   4, dev_player_hits_cached:   6
      )
      FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,3,30),
        main_player_hits:  5, main_player_hits_cached:  6,
        extra_player_hits: 7, extra_player_hits_cached: 8,
        dev_player_hits:   4, dev_player_hits_cached:   6
      )
      FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,4,30),
      main_player_hits:   9, main_player_hits_cached:  10,
      extra_player_hits: 11, extra_player_hits_cached: 12,
      dev_player_hits:    4, dev_player_hits_cached:    6
      )
    end

    context "with monthly plan" do
      before(:all) do
        @site.unmemoize_all
        @site.plan.cycle            = "month"
        @site.plan.video_views      = 100
        @site.plan_cycle_started_at = Time.utc(2011,3,20)
        @site.plan_cycle_ended_at   = Time.utc(2011,4,20)
        Timecop.travel(Time.utc(2011,3,25))
      end
      after(:all) { Timecop.return }
      subject { @site }

      its("current_monthly_billable_usages.sum") { should == 5 + 6 + 7 + 8 }
      its(:current_percentage_of_plan_used)     { should == 26 / 100.0 }
    end

    context "with monthly plan and overage" do
      before(:all) do
        @site.unmemoize_all
        @site.plan.cycle            = "month"
        @site.plan.video_views      = 10
        @site.plan_cycle_started_at = Time.utc(2011,4,20)
        @site.plan_cycle_ended_at   = Time.utc(2011,5,20)
        Timecop.travel(Time.utc(2011,4,25))
      end
      after(:all) { Timecop.return }
      subject { @site }

      its("current_monthly_billable_usages.sum") { should == 9 + 10 + 11 + 12 }
      its(:current_percentage_of_plan_used)     { should == 1 }
    end

    context "with yearly plan" do
      before(:all) do
        @site.unmemoize_all
        @site.plan.cycle            = "year"
        @site.plan.video_views      = 100
        @site.plan_cycle_started_at = Time.utc(2011,1,20)
        @site.plan_cycle_ended_at   = Time.utc(2012,1,20)
        Timecop.travel(Time.utc(2011,3,25))
      end
      after(:all) { Timecop.return }
      subject { @site }

      its("current_monthly_billable_usages.sum") { should == 5 + 6 + 7 + 8 }
      its(:current_percentage_of_plan_used)     { should == 26 / 100.0 }
    end

    context "with yearly plan (other date)" do
      before(:all) do
        @site.unmemoize_all
        @site.plan.cycle            = "year"
        @site.plan.video_views      = 1000
        @site.plan_cycle_started_at = Time.utc(2011,1,20)
        @site.plan_cycle_ended_at   = Time.utc(2012,1,20)
        Timecop.travel(Time.utc(2011,1,31))
      end
      after(:all) { Timecop.return }
      subject { @site }

      its("current_monthly_billable_usages.sum") { should == 1 + 2 + 3 + 4 }
      its(:current_percentage_of_plan_used)     { should == 10 / 1000.0 }
    end
  end

  describe "#current_percentage_of_plan_used" do
    it "should return 0 if plan video_views is 0" do
      site = FactoryGirl.create(:site, plan_id: @free_plan.id)
      site.current_percentage_of_plan_used.should == 0
    end
  end

  describe "#percentage_of_days_over_daily_limit(60)" do
    context "with free_plan" do
      subject { FactoryGirl.create(:site, plan_id: @free_plan.id) }

      its(:percentage_of_days_over_daily_limit) { should == 0 }
    end

    context "with paid plan" do
      before(:all) do
        @site = FactoryGirl.create(:site, plan_id: FactoryGirl.create(:plan, video_views: 30 * 300).id, first_paid_plan_started_at: Time.utc(2011,1,1))
      end

      describe "with 1 historic day and 1 over limit" do
        before(:each) do
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1),
            main_player_hits:  100, main_player_hits_cached:  100,
            extra_player_hits: 100, extra_player_hits_cached: 100,
            dev_player_hits:   100, dev_player_hits_cached:   100
          )
          Timecop.travel(Time.utc(2011,1,2))
        end
        after(:each) { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should == 1.0 }
      end

      describe "with 2 historic days and 1 over limit" do
        before(:each) do
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1), main_player_hits: 400)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,2), main_player_hits: 300)
          Timecop.travel(Time.utc(2011,1,3))
        end
        after(:each) { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should == 0.5 }
      end

      describe "with 5 historic days and 2 over limit" do
        before(:each) do
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1), main_player_hits: 400)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,2), main_player_hits: 300)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,3), main_player_hits: 500)
          Timecop.travel(Time.utc(2011,1,6))
        end
        after(:each) { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should == 2 / 5.0 }
      end

      describe "with >60 historic days and 2 over limit" do
        before(:each) do
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1), main_player_hits: 400)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,2,1), main_player_hits: 500)
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,3,1), main_player_hits: 500)
          Timecop.travel(Time.utc(2011,4,1))
        end
        after(:each) { Timecop.return }
        subject { @site }

        its(:percentage_of_days_over_daily_limit) { should == (2 / 60.0).round(2) }
      end
    end
  end

end
