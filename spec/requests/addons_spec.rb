require 'spec_helper'

feature 'Choose add-ons' do
  background do
    sign_in_as :user
    manager = Service::Site.build_site(attributes_for(:site).merge(user: @current_user))
    manager.save
    @site = manager.site
    @site.app_designs.should =~ [@classic_design, @flat_design, @light_design]
    @site.addon_plans.should =~ [@logo_addon_plan_1, @stats_addon_plan_1, @lightbox_addon_plan_1, @api_addon_plan, @support_addon_plan_1]
    @site.billable_item_activities.should have(8).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    go 'my', "/sites/#{@site.to_param}/addons"
  end

  scenario 'select radio button add-on' do
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

    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
  end
end

feature 'Opt-out from grandfather plan' do
  background do
    Plan.create(name: "plus",    cycle: "month", video_views: 200_000,   stats_retention_days: 365, price: 990,  support_level: 1)
    Plan.create(name: "premium", cycle: "month", video_views: 1_000_000, stats_retention_days: nil, price: 4990, support_level: 2)
  end

  context 'Plus plan' do
    background do
      sign_in_as :user
      @site = @current_user.sites.create(attributes_for(:site).merge(plan_id: Plan.where(name: 'plus', cycle: 'month').first.id), without_protection: true)
      @site.app_designs.should be_empty
      @site.addon_plans.should be_empty
      @site.billable_item_activities.should be_empty

      go 'my', "/sites/#{@site.to_param}/addons"
    end

    scenario 'select radio button add-on' do
      click_link "you can opt-out from your old Plus Plan"

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/plan/opt_out"

      click_button "Comfirm the opt-out from my old Plus Plan"

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons/thanks"
      page.should have_content 'Add-ons successfully updated.'

      @site.reload.app_designs.should =~ [@classic_design, @flat_design, @light_design]
      @site.addon_plans.should =~ [@logo_addon_plan_2, @stats_addon_plan_2, @lightbox_addon_plan_1, @api_addon_plan, @support_addon_plan_1]
      @site.billable_item_activities.should have(8).items
      @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan).where(state: 'subscribed').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    end
  end

  context 'Premium plan' do
    background do
      sign_in_as :user
      @site = @current_user.sites.create(attributes_for(:site).merge(plan_id: Plan.where(name: 'premium', cycle: 'month').first.id), without_protection: true)
      @site.app_designs.should be_empty
      @site.addon_plans.should be_empty
      @site.billable_item_activities.should be_empty

      go 'my', "/sites/#{@site.to_param}/addons"
    end

    scenario 'select radio button add-on' do
      click_link "you can opt-out from your old Premium Plan"

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/plan/opt_out"

      click_button "Comfirm the opt-out from my old Premium Plan"

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons/thanks"
      page.should have_content 'Add-ons successfully updated.'

      @site.reload.app_designs.should =~ [@classic_design, @flat_design, @light_design]
      @site.addon_plans.should =~ [@logo_addon_plan_2, @stats_addon_plan_2, @lightbox_addon_plan_1, @api_addon_plan, @support_addon_plan_2]
      @site.billable_item_activities.should have(8).items
      @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
      @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
      @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan).where(state: 'subscribed').should have(1).item
      @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'trial').should have(1).item
    end
  end
end
