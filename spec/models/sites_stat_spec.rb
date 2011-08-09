require 'spec_helper'

describe SitesStat do

  describe ".delay_create_sites_stats" do

    it "should delay create_sites_stats if not already delayed" do
      expect { SitesStat.delay_create_sites_stats }.should change(Delayed::Job.where(:handler.matches => '%SitesStat%create_sites_stats%'), :count).by(1)
    end

    it "should not delay create_sites_stats if already delayed" do
      SitesStat.delay_create_sites_stats
      expect { SitesStat.delay_create_sites_stats }.should change(Delayed::Job.where(:handler.matches => '%SitesStat%create_sites_stats%'), :count).by(0)
    end

    it "should delay create_sites_stats for next hour" do
      SitesStat.delay_create_sites_stats
      Delayed::Job.last.run_at.should == Time.new.utc.tomorrow.midnight
    end

  end

  context "with a bunch of different sites" do
    before(:all) do
      user = FactoryGirl.create(:user)
      @plan1 = FactoryGirl.create(:plan)
      @plan2 = FactoryGirl.create(:plan)
      FactoryGirl.create(:site, user: user, state: 'active', plan_id: @plan1.id)
      FactoryGirl.create(:site, user: user, state: 'archived', plan_id: @plan1.id)
      FactoryGirl.create(:site, user: user, state: 'suspended', plan_id: @plan2.id)
    end

    describe ".create_sites_stats" do

      it "should delay itself" do
        SitesStat.should_receive(:delay_create_sites_stats)
        SitesStat.create_sites_stats
      end

      it "should create sites stats for states & plans" do
        SitesStat.create_sites_stats
        SitesStat.count.should == 1
        sites_stat = SitesStat.last
        sites_stat.states_count.should == {
          "active"    => 1,
          "archived"  => 1,
          "suspended" => 1
        }
        sites_stat.plans_count.should == {
          @plan1.id.to_s => 2,
          @plan2.id.to_s => 1
        }
      end

    end

    describe ".states_count" do
      it "should include all used states" do
        SitesStat.states_count.should == {
          "active"    => 1,
          "archived"  => 1,
          "suspended" => 1
        }
      end
    end

    describe ".plans_count" do
      it "should include all used plans" do
        SitesStat.plans_count.should == {
          @plan1.id.to_s => 2,
          @plan2.id.to_s => 1
        }
      end
    end

  end

end
