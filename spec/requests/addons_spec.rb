require 'spec_helper'

feature 'Choose add-ons' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user)
    Service::Site.new(@site).create

    @site.reload.billable_items.should have(12).items
    @site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    @site.billable_item_activities.should have(12).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    go 'my', "/sites/#{@site.to_param}/addons"
  end

  scenario 'select radio button add-on' do
    choose "addon_plans_logo_#{@logo_addon_plan_2.id}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(2)

    @site.reload.billable_items.should have(12).items
    @site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    @site.billable_item_activities.should have(12 + 2).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item
  end

  scenario 'select checkbox add-on' do
    check "addon_plans_stats_#{@stats_addon_plan_2.id}"
    click_button 'Confirm selection'

    @site.reload.billable_items.should have(12).items
    @site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    @site.billable_item_activities.should have(12 + 2).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
  end
end
