# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".regenerate_all_loaders_and_licenses" do
    before(:all) do
      ::Site.delete_all
      FactoryGirl.create(:site)
      FactoryGirl.create(:site)
      FactoryGirl.create(:site, state: 'archived')
    end

    it "regenerates loader and license of all sites" do
      Delayed::Job.delete_all
      count_before = Delayed::Job.where(:handler.matches => "%update_loader_and_license%").count
      lambda { described_class.regenerate_all_loaders_and_licenses }.should change(Delayed::Job, :count).by(2)
      djs = Delayed::Job.where(:handler.matches => "%update_loader_and_license%")
      djs.count.should == count_before + 2
    end
  end

  describe ".set_trial_started_at_for_sites_created_before_v2" do
    before(:all) do
      ::Site.delete_all
      Site.skip_callback(:save, :before, :set_trial_started_at)
      @old_site_to_update     = FactoryGirl.create(:site, first_paid_plan_started_at: Time.utc(2010,1,1))
      @old_site_not_to_update = FactoryGirl.create(:site, first_paid_plan_started_at: nil)
      Site.set_callback(:save, :before, :set_trial_started_at)
    end

    it "moves local domains present in extra domains into dev domains" do
      @old_site_to_update.trial_started_at.should be_nil
      @old_site_to_update.first_paid_plan_started_at.should be_present
      @old_site_not_to_update.trial_started_at.should be_nil
      @old_site_not_to_update.first_paid_plan_started_at.should be_nil

      described_class.set_trial_started_at_for_sites_created_before_v2

      @old_site_to_update.reload.trial_started_at.should eql @old_site_to_update.first_paid_plan_started_at - BusinessModel.days_for_trial.days
      @old_site_to_update.first_paid_plan_started_at.should be_present

      @old_site_not_to_update.reload.trial_started_at.should be_nil
      @old_site_not_to_update.first_paid_plan_started_at.should be_nil
    end
  end

  describe ".current_sites_plans_migration" do
    before(:all) do
      plans_attributes = [
        { name: "dev",       cycle: "none",  video_views: 0,          price: 0 },
        { name: "sponsored", cycle: "none",  video_views: 0,          price: 0 },
        { name: "comet",     cycle: "month", video_views: 3_000,      price: 990 },
        { name: "planet",    cycle: "month", video_views: 50_000,     price: 1990 },
        { name: "star",      cycle: "month", video_views: 200_000,    price: 4990 },
        { name: "galaxy",    cycle: "month", video_views: 1_000_000,  price: 9990 },
        { name: "comet",     cycle: "year",  video_views: 3_000,      price: 9900 },
        { name: "planet",    cycle: "year",  video_views: 50_000,     price: 19900 },
        { name: "star",      cycle: "year",  video_views: 200_000,    price: 49900 },
        { name: "galaxy",    cycle: "year",  video_views: 1_000_000,  price: 99900 },
        { name: "custom1",   cycle: "year",  video_views: 10_000_000, price: 999900 },
        { name: "free",      cycle: "none",  video_views: 0,          price: 0 },
        { name: "silver",    cycle: "month", video_views: 200_000,    price: 4990 },
        { name: "gold",      cycle: "month", video_views: 1_000_000,  price: 9990 },
        { name: "silver",    cycle: "year",  video_views: 200_000,    price: 49900 },
        { name: "gold",      cycle: "year",  video_views: 1_000_000,  price: 99900 }
      ]
      plans_attributes.each { |attributes| Plan.create(attributes) }
      @dev_plan       = Plan.where(name: 'dev').first
      @sponsored_plan = Plan.where(name: 'sponsored').first
      @comet_m_plan   = Plan.where(name: 'comet', cycle: 'month').first
      @comet_y_plan   = Plan.where(name: 'comet', cycle: 'year').first
      @planet_m_plan  = Plan.where(name: 'planet', cycle: 'month').first
      @planet_y_plan  = Plan.where(name: 'planet', cycle: 'year').first
      @star_m_plan    = Plan.where(name: 'star', cycle: 'month').first
      @star_y_plan    = Plan.where(name: 'star', cycle: 'year').first
      @galaxy_m_plan  = Plan.where(name: 'galaxy', cycle: 'month').first
      @galaxy_y_plan  = Plan.where(name: 'galaxy', cycle: 'year').first
      @custom_plan    = Plan.where(name: 'custom1').first

      @free_plan     = Plan.where(name: 'free').first
      @silver_m_plan = Plan.where(name: 'silver', cycle: 'month').first
      @silver_y_plan = Plan.where(name: 'silver', cycle: 'year').first
      @gold_m_plan   = Plan.where(name: 'gold', cycle: 'month').first
      @gold_y_plan   = Plan.where(name: 'gold', cycle: 'year').first

      ::Site.delete_all
      @site_dev       = FactoryGirl.create(:site, plan_id: @dev_plan.id)
      @site_sponsored = FactoryGirl.create(:site)
      @site_sponsored.sponsor!
      @site_comet_m   = FactoryGirl.create(:site, plan_id: @comet_m_plan.id)
      @site_comet_y   = FactoryGirl.create(:site, plan_id: @comet_y_plan.id)
      @site_planet_m  = FactoryGirl.create(:site, plan_id: @planet_m_plan.id)
      @site_planet_y  = FactoryGirl.create(:site, plan_id: @planet_y_plan.id)
      @site_star_m    = FactoryGirl.create(:site, plan_id: @star_m_plan.id)
      @site_star_y    = FactoryGirl.create(:site, plan_id: @star_y_plan.id)
      @site_galaxy_m  = FactoryGirl.create(:site, plan_id: @galaxy_m_plan.id)
      @site_galaxy_y  = FactoryGirl.create(:site, plan_id: @galaxy_y_plan.id)
      @site_custom    = FactoryGirl.create(:site, plan_id: @custom_plan.token)
    end

    pending "moves local domains present in extra domains into dev domains" do
      @site_dev.plan.should eql @dev_plan
      @site_sponsored.plan.should eql @sponsored_plan
      @site_comet_m.plan.should eql @comet_m_plan
      @site_comet_y.plan.should eql @comet_y_plan
      @site_planet_m.plan.should eql @planet_m_plan
      @site_planet_y.plan.should eql @planet_y_plan
      @site_star_m.plan.should eql @star_m_plan
      @site_star_y.plan.should eql @star_y_plan
      @site_galaxy_m.plan.should eql @galaxy_m_plan
      @site_galaxy_y.plan.should eql @galaxy_y_plan
      @site_custom.plan.should eql @custom_plan

      described_class.current_sites_plans_migration

      @site_dev.reload.plan.should eql @free_plan
      @site_sponsored.reload.plan.should eql @sponsored_plan
      @site_comet_m.reload.plan.should eql @silver_m_plan
      @site_comet_y.reload.plan.should eql @silver_y_plan
      @site_planet_m.reload.plan.should eql @silver_m_plan
      @site_planet_y.reload.plan.should eql @silver_y_plan
      @site_star_m.reload.plan.should eql @gold_m_plan
      @site_star_y.reload.plan.should eql @gold_y_plan
      @site_galaxy_m.reload.plan.should eql @gold_m_plan
      @site_galaxy_y.reload.plan.should eql @gold_y_plan
      @site_custom.reload.plan.should eql @custom_plan
    end
  end

end