require 'spec_helper'

describe Stats::SitesStat do

  describe ".delay_create_sites_stats" do

    it "should delay create_sites_stats if not already delayed" do
      expect { described_class.delay_create_sites_stats }.should change(Delayed::Job.where(:handler.matches => '%SitesStat%create_sites_stats%'), :count).by(1)
    end

    it "should not delay create_sites_stats if already delayed" do
      described_class.delay_create_sites_stats
      expect { described_class.delay_create_sites_stats }.should change(Delayed::Job.where(:handler.matches => '%SitesStat%create_sites_stats%'), :count).by(0)
    end

    it "should delay create_sites_stats for next hour" do
      described_class.delay_create_sites_stats
      Delayed::Job.last.run_at.should eq Time.new.utc.tomorrow.midnight
    end

  end

  context "with a bunch of different sites" do
    before(:all) do
      user = Factory.create(:user)
      @yearly_plan = Factory.create(:plan, name: @paid_plan.name, cycle: 'year')
      Factory.create(:site, user: user, state: 'active', plan_id: @free_plan.id)
      site = Factory.create(:site, user: user, state: 'active', plan_id: @free_plan.id)
      site.sponsor!
      Factory.create(:site, user: user, state: 'active', plan_id: @paid_plan.id) # in trial
      Factory.create(:site, user: user, state: 'active', plan_id: @custom_plan.token) # in trial
      Factory.create(:site, user: user, state: 'active', plan_id: @custom_plan.token) # in trial
      Factory.create(:site_not_in_trial, user: user, state: 'active', plan_id: @paid_plan.id) # not in trial
      Factory.create(:site_not_in_trial, user: user, state: 'active', plan_id: @yearly_plan.id) # not in trial
      Factory.create(:site_not_in_trial, user: user, state: 'active', plan_id: @custom_plan.token) # not in trial
      Factory.create(:site, user: user, state: 'suspended', plan_id: @custom_plan.token)
      Factory.create(:site, user: user, state: 'archived', plan_id: @paid_plan.id)
    end

    describe ".create_sites_stats" do

      it "should delay itself" do
        described_class.should_receive(:delay_create_sites_stats)
        described_class.create_sites_stats
      end

      it "should create sites stats for states & plans" do
        described_class.create_sites_stats
        described_class.count.should eq 1
        sites_stat = described_class.last
        sites_stat.states_count.should == {
          "active"    => 8,
          "archived"  => 1,
          "suspended" => 1
        }
        sites_stat.plans_count.should == {
          @free_plan.id.to_s => 1,
          @paid_plan.id.to_s => 3,
          @sponsored_plan.id.to_s => 1,
          @custom_plan.id.to_s => 4,
          @yearly_plan.id.to_s => 1
        }
        sites_stat["fr"].should eq 1
        sites_stat["sp"].should eq 1
        sites_stat["tr"].should eq 3
        sites_stat["pa"].should eq 3
        sites_stat["tr_details"].should == {
          @paid_plan.name => { "m" => 1, "y" => 0 },
          @custom_plan.name => { "m" => 2 }
        }
        sites_stat["pa_details"].should == {
          @paid_plan.name => { "m" => 1, "y" => 1 },
          @custom_plan.name => { "m" => 1 }
        }
        sites_stat["su"].should eq 1
        sites_stat["ar"].should eq 1
      end

    end

    describe ".states_count" do
      it "should include all used states" do
        described_class.states_count.should == {
          "active"    => 8,
          "archived"  => 1,
          "suspended" => 1
        }
      end
    end

    describe ".plans_count" do
      it "should include all used plans" do
        described_class.plans_count.should == {
          @free_plan.id.to_s => 1,
          @paid_plan.id.to_s => 3,
          @sponsored_plan.id.to_s => 1,
          @custom_plan.id.to_s => 4,
          @yearly_plan.id.to_s => 1
        }
      end
    end

  end

end
