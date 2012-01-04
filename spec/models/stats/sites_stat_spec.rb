require 'spec_helper'

describe Stats::SitesStat do

  describe ".delay_create_sites_stats" do

    it "should delay create_sites_stats if not already delayed" do
      expect { described_class.delay_create_sites_stats }.should change(Delayed::Job.where(:handler.matches => '%Stats::SitesStat%create_sites_stats%'), :count).by(1)
    end

    it "should not delay create_sites_stats if already delayed" do
      described_class.delay_create_sites_stats
      expect { described_class.delay_create_sites_stats }.should change(Delayed::Job.where(:handler.matches => '%Stats::SitesStat%create_sites_stats%'), :count).by(0)
    end

    it "should delay create_sites_stats for next day" do
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
        sites_stat["fr"].should == { "free" => 1 }
        sites_stat["sp"].should eq 1
        sites_stat["tr"].should == {
          @paid_plan.name => { "m" => 1, "y" => 0 },
          @custom_plan.name => { "m" => 2 }
        }
        sites_stat["pa"].should == {
          @paid_plan.name => { "m" => 1, "y" => 1 },
          @custom_plan.name => { "m" => 1 }
        }
        sites_stat["su"].should eq 1
        sites_stat["ar"].should eq 1
      end

    end

  end

end
