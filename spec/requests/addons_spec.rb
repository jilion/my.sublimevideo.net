require 'spec_helper'

feature 'Choose add-ons' do
  background do
    sign_in_as :user
    manager = Services::Sites::Manager.build_site(attributes_for(:site).merge(user: @current_user))
    manager.save
    @site = manager.site
    go 'my', "/sites/#{@site.to_param}/addons"
  end

  scenario 'select radio button add-on' do
    @site.reload.app_designs.should =~ [@classic_design, @flat_design, @light_design]
    @site.addon_plans.should =~ [@logo_addon_plan_1, @stats_addon_plan_1, @lightbox_addon_plan_1, @api_addon_plan, @support_addon_plan_1]
    @site.billable_item_activities.should have(8).items
    puts @site.billable_item_activities.inspect

    choose "addon_plans_logo_#{@logo_addon_plan_2.id}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(2)

    @site.reload.app_designs.should =~ [@classic_design, @flat_design, @light_design]
    @site.addon_plans.should =~ [@logo_addon_plan_2, @stats_addon_plan_1, @lightbox_addon_plan_1, @api_addon_plan, @support_addon_plan_1]

    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item
  end

  scenario 'select checkbox add-on' do
    @site.reload.addon_plans.should =~ [@logo_addon_plan_1, @stats_addon_plan_1, @lightbox_addon_plan_1, @api_addon_plan, @support_addon_plan_1]

    check "addon_plans_stats_#{@stats_addon_plan_2.id}"
    click_button 'Confirm selection'

    @site.reload.addon_plans.should =~ [@logo_addon_plan_1, @stats_addon_plan_2, @lightbox_addon_plan_1, @api_addon_plan, @support_addon_plan_1]
  end
end
