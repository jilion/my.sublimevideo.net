# coding: utf-8
require 'spec_helper'
require 'one_time/site'

describe OneTime::Site do

  describe '.regenerate_templates' do
    before do
      create(:site)
      create(:site, state: 'archived')
    end

    it 'regenerates loader and license of all sites' do
      -> { described_class.regenerate_templates(loaders: true) }.should delay('%Service::Loader%update_all_stages%')
      -> { described_class.regenerate_templates(settings: true) }.should delay('%Service::Settings%update_all_types%')
    end
  end

  describe '.add_already_paid_amount_to_balance_for_monthly_plans' do
    before do
      create_plans
      @plus_monthly    = Plan.where(name: 'plus', cycle: 'month').first
      @plus_yearly     = Plan.where(name: 'plus', cycle: 'year').first
      @premium_monthly = Plan.where(name: 'premium', cycle: 'month').first
      @premium_yearly  = Plan.where(name: 'premium', cycle: 'year').first

      @site_plus_monthly            = create(:site, plan_id: @plus_monthly.id, hostname: 'plus-monthly.com', plan_cycle_ended_at: 15.days.from_now.end_of_day)
      @site_plus_yearly             = create(:site, plan_id: @plus_yearly.id, hostname: 'plus-yearly.com', plan_cycle_ended_at: 20.days.from_now.end_of_day)
      @site_premium_monthly         = create(:site, plan_id: @premium_monthly.id, hostname: 'premium-monthly.com', plan_cycle_ended_at: 25.days.from_now.end_of_day)
      @site_premium_yearly          = create(:site, plan_id: @premium_yearly.id, hostname: 'premium-yearly.com', plan_cycle_ended_at: 30.days.from_now.end_of_day)
      @site_plus_yearly_suspended   = create(:site, plan_id: @plus_monthly.id, state: 'suspended', hostname: 'plus-yearly.com', plan_cycle_ended_at: 90.days.ago.end_of_day)
      @site_premium_yearly_archived = create(:site, plan_id: @plus_yearly.id, state: 'archived')
    end

    it 'adds already paid plan price (prorated between Oct. 23 and end of cycle) to balance' do
      described_class.add_already_paid_amount_to_balance_for_monthly_plans

      # balance check
      @site_plus_monthly.user.reload.balance.should eq ((@plus_monthly.price * 12) / 365) * 15
      @site_plus_yearly.user.reload.balance.should eq 0
      @site_premium_monthly.user.reload.balance.should eq ((@premium_monthly.price * 12) / 365) * 25
      @site_premium_yearly.user.reload.balance.should eq 0
      @site_plus_yearly_suspended.user.reload.balance.should eq 0
      @site_premium_yearly_archived.user.reload.balance.should eq 0
    end
  end

  describe '.migrate_yearly_plans_to_monthly_plans' do
    before do
      create_plans
      @plus_monthly    = Plan.where(name: 'plus', cycle: 'month').first
      @plus_yearly     = Plan.where(name: 'plus', cycle: 'year').first
      @premium_monthly = Plan.where(name: 'premium', cycle: 'month').first
      @premium_yearly  = Plan.where(name: 'premium', cycle: 'year').first

      @site_plus_monthly            = create(:site, plan_id: @plus_monthly.id, hostname: 'plus-monthly.com')
      @site_plus_yearly             = create(:site, plan_id: @plus_yearly.id, hostname: 'plus-yearly.com', plan_cycle_ended_at: 30.days.from_now.end_of_day)
      @site_premium_monthly         = create(:site, plan_id: @premium_monthly.id, hostname: 'premium-monthly.com')
      @site_premium_yearly          = create(:site, plan_id: @premium_yearly.id, hostname: 'premium-yearly.com', plan_cycle_ended_at: 60.days.from_now.end_of_day)
      @site_plus_yearly_suspended   = create(:site, plan_id: @plus_yearly.id, state: 'suspended', hostname: 'plus-yearly.com', plan_cycle_ended_at: 90.days.ago.end_of_day)
      @site_premium_yearly_archived = create(:site, plan_id: @premium_yearly.id, state: 'archived')
    end

    it 'change plans to monthly and add to balance' do
      described_class.migrate_yearly_plans_to_monthly_plans

      # plans check
      @site_plus_monthly.reload.plan.should eq @plus_monthly
      @site_plus_yearly.reload.plan.should eq @plus_monthly
      @site_premium_monthly.reload.plan.should eq @premium_monthly
      @site_premium_yearly.reload.plan.should eq @premium_monthly
      @site_plus_yearly_suspended.reload.plan.should eq @plus_monthly
      @site_premium_yearly_archived.reload.plan.should eq @premium_yearly

      # balance check
      @site_plus_monthly.user.reload.balance.should eq 0
      @site_plus_yearly.user.reload.balance.should eq ((@plus_monthly.price * 12) / 365) * 30
      @site_premium_monthly.user.reload.balance.should eq 0
      @site_premium_yearly.user.reload.balance.should eq ((@premium_monthly.price * 12) / 365) * 60
      @site_plus_yearly_suspended.user.reload.balance.should eq 0
      @site_premium_yearly_archived.user.reload.balance.should eq 0
    end
  end

  describe '.migrate_plans_to_addons', :addons do
    before do
      create_plans
      @free      = Plan.where(name: 'free').first
      @sponsored = Plan.where(name: 'sponsored').first
      @trial     = Plan.where(name: 'trial').first
      @plus      = Plan.where(name: 'plus', cycle: 'month').first
      @premium   = Plan.where(name: 'premium', cycle: 'month').first

      @site_free      = create(:site, plan_id: @free.id, hostname: 'free.com')
      @site_sponsored = create(:site, plan_id: @sponsored.id, hostname: 'sponsored.com')
      @site_trial     = create(:site, plan_id: @trial.id, hostname: 'trial.com')
      @site_plus      = create(:site, plan_id: @plus.id, hostname: 'plus.com')
      @site_premium   = create(:site, plan_id: @premium.id, hostname: 'premium.com')
      @site_suspended = create(:site, plan_id: @premium.id, state: 'suspended')
      @site_archived  = create(:site, plan_id: @premium.id, state: 'archived')
    end

    it 'migrate plans to add-ons' do
      @site_free.reload.billable_items.should be_empty
      @site_sponsored.reload.billable_items.should be_empty
      @site_trial.reload.billable_items.should be_empty
      @site_plus.reload.billable_items.should be_empty
      @site_premium.reload.billable_items.should be_empty
      @site_archived.reload.billable_items.should be_empty

      described_class.migrate_plans_to_addons

      $worker.work_off

      # free check
      @site_free.reload.billable_items.should have(12).items
      @site_free.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_free.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_free.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

      @site_free.billable_item_activities.should have(12).items
      @site_free.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_free.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_free.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_free.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

      # sponsored check
      @site_sponsored.reload.billable_items.should have(12).items
      @site_sponsored.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_sponsored.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_sponsored.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'sponsored').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'sponsored').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_items.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'sponsored').should have(1).item

      @site_sponsored.billable_item_activities.should have(12).items
      @site_sponsored.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_sponsored.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_sponsored.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'sponsored').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'sponsored').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_sponsored.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'sponsored').should have(1).item

      # trial check
      @site_trial.reload.billable_items.should have(12).items
      @site_trial.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_trial.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_trial.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

      @site_trial.billable_item_activities.should have(12).items
      @site_trial.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_trial.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_trial.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_trial.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

      # plus check
      @site_plus.reload.billable_items.should have(12).items
      @site_plus.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_plus.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_plus.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'subscribed').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'sponsored').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

      @site_plus.billable_item_activities.should have(12).items
      @site_plus.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_plus.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_plus.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'subscribed').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'sponsored').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_plus.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

      # premium check
      @site_premium.reload.billable_items.should have(12).items
      @site_premium.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_premium.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_premium.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_items.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'sponsored').should have(1).item

      @site_premium.billable_item_activities.should have(12).items
      @site_premium.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site_premium.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site_premium.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site_premium.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'sponsored').should have(1).item

      # suspended check
      @site_suspended.reload.billable_items.should have(12).items
      @site_suspended.billable_items.app_designs.where(item_id: @classic_design).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.app_designs.where(item_id: @flat_design).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.app_designs.where(item_id: @light_design).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_items.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'suspended').should have(1).item

      @site_suspended.billable_item_activities.should have(12).items
      @site_suspended.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'suspended').should have(1).item
      @site_suspended.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'suspended').should have(1).item

      # archived check
      @site_archived.reload.billable_items.should be_empty
    end
  end

  describe '.create_default_kit_for_all_non_archived_sites' do
    before do
      create(:app_design)
      @site_active    = create(:site, state: 'active')
      @site_suspended = create(:site, state: 'suspended')
      @site_archived  = create(:site, state: 'archived')
    end

    it 'creates default kit for all non-archived sites' do
      described_class.create_default_kit_for_all_non_archived_sites

      @site_active.reload.kits.should have(1).item
      @site_suspended.reload.kits.should have(1).item
      @site_archived.reload.kits.should be_empty
    end
  end

  describe ".update_accessible_stage" do
    before do
      @site_active_stable    = create(:site, state: 'active', accessible_stage: 'stable')
      @site_active_alpha     = create(:site, state: 'active', accessible_stage: 'alpha')
      @site_active_dev       = build(:site, state: 'active', accessible_stage: 'dev')
      @site_active_dev.save(validate: false)
      @site_suspended_stable = create(:site, state: 'suspended', accessible_stage: 'stable')
      @site_suspended_alpha  = create(:site, state: 'suspended', accessible_stage: 'alpha')
      @site_archived         = create(:site, state: 'archived', accessible_stage: 'stable')
    end

    it "updates non-archived site with accessible_stage at 'stable' to 'beta'" do
      described_class.update_accessible_stage

      @site_active_stable.reload.accessible_stage.should eq('beta')
      @site_active_alpha.reload.accessible_stage.should eq('alpha')
      @site_suspended_stable.reload.accessible_stage.should eq('beta')
      @site_suspended_alpha.reload.accessible_stage.should eq('alpha')
      @site_archived.reload.accessible_stage.should eq('stable')
    end

    it "updates non-archived site with accessible_stage at 'dev' to 'alpha'" do
      described_class.update_accessible_stage

      @site_active_dev.reload.accessible_stage.should eq('alpha')
    end
  end
end

def create_plans
  plans_attributes = [
    { name: "free",      cycle: "none",  video_views: 0,         stats_retention_days: 0,   price: 0,    support_level: 0 },
    { name: "sponsored", cycle: "none",  video_views: 0,         stats_retention_days: nil, price: 0,    support_level: 0 },
    { name: "trial",     cycle: "none",  video_views: 0,         stats_retention_days: nil, price: 0,    support_level: 2 },
    { name: "plus",      cycle: "month", video_views: 200_000,   stats_retention_days: 365, price: 990,  support_level: 1 },
    { name: "premium",   cycle: "month", video_views: 1_000_000, stats_retention_days: nil, price: 4990, support_level: 2 },
    { name: "plus",       cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
    { name: "premium",    cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 },
    { name: "custom - 1", cycle: "year",  video_views: 10_000_000, stats_retention_days: nil, price: 99900, support_level: 2 }
  ]
  plans_attributes.each { |attributes| Plan.create!(attributes) }
end
