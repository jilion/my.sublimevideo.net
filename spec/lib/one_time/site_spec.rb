# coding: utf-8
require 'spec_helper'

describe OneTime::Site do

  describe ".regenerate_all_loaders_and_licenses" do
    before(:all) do
      ::Site.delete_all
      Factory.create(:site)
      Factory.create(:site)
      Factory.create(:site, state: 'archived')
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
      @old_site_to_update     = Factory.create(:site, first_paid_plan_started_at: Time.utc(2010,1,1))
      @old_site_not_to_update = Factory.create(:site, first_paid_plan_started_at: nil)
      Site.set_callback(:save, :before, :set_trial_started_at)
    end

    it "does the job" do
      @old_site_to_update.trial_started_at.should be_nil
      @old_site_to_update.first_paid_plan_started_at.should be_present
      @old_site_not_to_update.trial_started_at.should be_nil
      @old_site_not_to_update.first_paid_plan_started_at.should be_nil

      described_class.set_trial_started_at_for_sites_created_before_v2

      @old_site_to_update.reload.trial_started_at.should eq @old_site_to_update.first_paid_plan_started_at - BusinessModel.days_for_trial.days
      @old_site_to_update.first_paid_plan_started_at.should be_present
      @old_site_not_to_update.reload.trial_started_at.should be_nil
      @old_site_not_to_update.first_paid_plan_started_at.should be_nil
    end
  end

  describe ".current_sites_plans_migration" do
    before(:all) do
      ::Site.delete_all
      ::Plan.delete_all
      plans_attributes = [
        { name: "dev",        cycle: "none",  video_views: 0,          price: 0 },
        { name: "sponsored",  cycle: "none",  video_views: 0,          price: 0 },
        { name: "comet",      cycle: "month", video_views: 3_000,      price: 990 },
        { name: "planet",     cycle: "month", video_views: 50_000,     price: 1990 },
        { name: "star",       cycle: "month", video_views: 200_000,    price: 4990 },
        { name: "galaxy",     cycle: "month", video_views: 1_000_000,  price: 9990 },
        { name: "comet",      cycle: "year",  video_views: 3_000,      price: 9900 },
        { name: "planet",     cycle: "year",  video_views: 50_000,     price: 19900 },
        { name: "star",       cycle: "year",  video_views: 200_000,    price: 49900 },
        { name: "galaxy",     cycle: "year",  video_views: 1_000_000,  price: 99900 },
        { name: "custom - 1", cycle: "year",  video_views: 10_000_000, price: 999900 },

        { name: "free",       cycle: "none",  video_views: 0,          price: 0 },
        { name: "silver",     cycle: "month", video_views: 200_000,    price: 990 },
        { name: "gold",       cycle: "month", video_views: 1_000_000,  price: 4990 },
        { name: "silver",     cycle: "year",  video_views: 200_000,    price: 9900 },
        { name: "gold",       cycle: "year",  video_views: 1_000_000,  price: 49900 }
      ]
      plans_attributes.each { |attributes| Factory.create(:plan, attributes) }
      @dev_plan       = ::Plan.where(name: 'dev').first
      @sponsored_plan = ::Plan.where(name: 'sponsored').first
      @comet_m_plan   = ::Plan.where(name: 'comet', cycle: 'month').first
      @comet_y_plan   = ::Plan.where(name: 'comet', cycle: 'year').first
      @planet_m_plan  = ::Plan.where(name: 'planet', cycle: 'month').first
      @planet_y_plan  = ::Plan.where(name: 'planet', cycle: 'year').first
      @star_m_plan    = ::Plan.where(name: 'star', cycle: 'month').first
      @star_y_plan    = ::Plan.where(name: 'star', cycle: 'year').first
      @galaxy_m_plan  = ::Plan.where(name: 'galaxy', cycle: 'month').first
      @galaxy_y_plan  = ::Plan.where(name: 'galaxy', cycle: 'year').first
      @custom_plan    = ::Plan.where(name: 'custom - 1').first

      @free_plan     = ::Plan.where(name: 'free').first
      @silver_m_plan = ::Plan.where(name: 'silver', cycle: 'month').first
      @silver_y_plan = ::Plan.where(name: 'silver', cycle: 'year').first
      @gold_m_plan   = ::Plan.where(name: 'gold', cycle: 'month').first
      @gold_y_plan   = ::Plan.where(name: 'gold', cycle: 'year').first

      @site_dev       = Factory.create(:site, plan_id: @dev_plan.id)

      @site_sponsored = Factory.create(:site)
      @site_sponsored.sponsor!

      @site_comet_m   = Factory.create(:site_with_invoice, plan_id: @comet_m_plan.id)

      @site_comet_y   = Factory.create(:site_with_invoice, plan_id: @comet_y_plan.id)

      @site_planet_m  = Factory.create(:site_with_invoice, plan_id: @planet_m_plan.id)
      Timecop.travel(35.days.from_now) do
        invoice = ::Invoice.construct(site: @site_planet_m, renew: true)
        invoice.save!
        @site_planet_m.invoices.order(:id).last.should be_renew
        @site_planet_m.invoices.order(:id).last.should be_open
      end

      # This site got the beta discount + VAT
      @site_planet_y = Factory.create(:site_with_invoice, plan_id: @planet_y_plan.id)
      plan_invoice_item = @site_planet_y.invoices.last.plan_invoice_items.first
      plan_invoice_item.discounted_percentage = 0.2
      plan_invoice_item.price = plan_invoice_item.amount = ((19900*0.8) / 100).to_i * 100
      plan_invoice_item.save!

      last_invoice = @site_planet_y.invoices.last
      last_invoice.invoice_items_amount = last_invoice.amount = (((19900*0.8) / 100).to_i * 100)*1.08
      last_invoice.save!

      @site_star_m = Factory.create(:site_with_invoice, plan_id: @star_m_plan.id)
      Timecop.travel(35.days.from_now) do
        invoice = ::Invoice.construct(site: @site_star_m, renew: true)
        invoice.save!
        @site_star_m.invoices.order(:id).last.update_attribute(:state, 'failed')
        @site_star_m.invoices.order(:id).last.should be_renew
        @site_star_m.invoices.order(:id).last.should be_failed
      end

      # downgrade and next plan is not the same as the new plan
      @site_star_y = Factory.create(:site_with_invoice, plan_id: @star_y_plan.id)
      @site_star_y.update_attribute(:next_cycle_plan_id, @planet_y_plan.id)
      @site_star_y.next_cycle_plan.should eq @planet_y_plan

      @site_galaxy_m = Factory.create(:site_with_invoice, plan_id: @galaxy_m_plan.id)

      # downgrade and next plan is the same as the new plan => next cycle plan removed
      @site_galaxy_y = Factory.create(:site_with_invoice, plan_id: @galaxy_y_plan.id)
      @site_galaxy_y.update_attribute(:next_cycle_plan_id, @star_y_plan.id)
      @site_galaxy_y.next_cycle_plan.should eq @star_y_plan

      @site_custom = Factory.create(:site_with_invoice, plan_id: @custom_plan.token)

      @site_dev.plan.should eq @dev_plan
      @site_sponsored.plan.should eq @sponsored_plan
      @site_comet_m.plan.should eq @comet_m_plan
      @site_comet_y.plan.should eq @comet_y_plan
      @site_planet_m.plan.should eq @planet_m_plan
      @site_planet_y.plan.should eq @planet_y_plan
      @site_star_m.plan.should eq @star_m_plan
      @site_star_y.plan.should eq @star_y_plan
      @site_galaxy_m.plan.should eq @galaxy_m_plan
      @site_galaxy_y.plan.should eq @galaxy_y_plan
      @site_custom.plan.should eq @custom_plan

      described_class.current_sites_plans_migration
    end

    it "dev => free" do
      @site_dev.reload.plan.should eq @free_plan
    end

    it "sponsored => sponsored" do
      @site_sponsored.reload.plan.should eq @sponsored_plan
      @site_sponsored.user.balance.should eq 0
    end

    it "comet month => silver month" do
      @site_comet_m.reload.plan.should eq @silver_m_plan
      @site_comet_m.user.balance.should eq 0
    end

    it "comet year => silver year" do
      @site_comet_y.reload.plan.should eq @silver_y_plan
      @site_comet_y.user.balance.should eq 0
    end

    it "planet month => silver month" do
      @site_planet_m.reload.plan.should eq @silver_m_plan
      @site_planet_m.user.balance.should eq 0
    end

    it "planet year => silver year" do
      @site_planet_y.reload.plan.should eq @silver_y_plan

      @site_planet_y.user.balance.should eq (((19900 * (1.0 - 0.2) / 100).to_i * 100)*1.08).to_i - (((9900 * (1.0 - 0.2) / 100).to_i * 100)*1.08).to_i # include vat
    end

    it "star month => gold month" do
      @site_star_m.reload.plan.should eq @gold_m_plan
      @site_star_m.user.balance.should eq 0
    end

    it "updates open & renew invoice with new plans and prices" do
      last_invoice = @site_planet_m.invoices.order(:id).last
      last_invoice.vat_amount.should eq (@silver_m_plan.price * last_invoice.vat_rate).round
      last_invoice.amount.should eq @silver_m_plan.price + (@silver_m_plan.price * last_invoice.vat_rate).round

      last_plan_invoice_item = last_invoice.plan_invoice_items.last
      last_plan_invoice_item.item.should eq @silver_m_plan
      last_plan_invoice_item.price.should eq @silver_m_plan.price
      last_plan_invoice_item.amount.should eq @silver_m_plan.price
    end

    it "updates failed & renew invoice with new plans and prices" do
      last_invoice = @site_star_m.invoices.order(:id.asc).last
      last_invoice.vat_amount.should eq (@gold_m_plan.price * last_invoice.vat_rate).round
      last_invoice.amount.should eq @gold_m_plan.price + (@gold_m_plan.price * last_invoice.vat_rate).round

      last_plan_invoice_item = last_invoice.plan_invoice_items.last
      last_plan_invoice_item.item.should eq @gold_m_plan
      last_plan_invoice_item.price.should eq @gold_m_plan.price
      last_plan_invoice_item.amount.should eq @gold_m_plan.price
    end

    it "star year => gold year" do
      @site_star_y.reload.plan.should eq @gold_y_plan
      @site_star_y.user.balance.should eq 0
    end

    it "updates next cycle plan if it's not the same" do
      @site_star_y.reload.next_cycle_plan.should eq @silver_y_plan
    end

    it "galaxy month => gold month" do
      @site_galaxy_m.reload.plan.should eq @gold_m_plan
      @site_galaxy_m.user.balance.should eq 0
    end

    it "galaxy year => gold year" do
      @site_galaxy_y.reload.plan.should eq @gold_y_plan
      @site_galaxy_y.user.balance.should eq ((99900*1.08) - (49900*1.08)).to_i
    end

    it "clears next cycle plan if it's the same" do
      @site_galaxy_y.reload.next_cycle_plan.should be_nil
    end

    it "custom => custom" do
      @site_custom.reload.plan.should eq @custom_plan
      @site_custom.user.balance.should eq 0
    end

  end

end