require 'spec_helper'

feature 'special /addons page' do
  context 'user is not logged-in without any site' do
    background do
      @user = create(:user, use_clients: true)
    end

    scenario 'redirects to /login and then to /assistant/new-site' do
      go 'my', 'addons'
      current_url.should eq "http://my.sublimevideo.dev/login"
      fill_and_submit_login(@user)
      current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    end
  end

  context 'user is not logged-in with 1 site' do
    background do
      @user = create(:user, use_clients: true)
      @site = build(:site, user: @user)
      Service::Site.new(@site).create
    end

    scenario 'redirects to /login and then to /sites/:token/addons' do
      go 'my', 'addons'
      current_url.should eq "http://my.sublimevideo.dev/login"
      fill_and_submit_login(@user)
      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    end
  end

  context 'user is not logged-in with more than 1 site' do
    background do
      @user = create(:user, use_clients: true)
      Service::Site.new(build(:site, user: @user)).create
      Service::Site.new(build(:site, user: @user)).create
    end

    scenario 'redirects to /login and then to /sites' do
      go 'my', 'addons'
      current_url.should eq "http://my.sublimevideo.dev/login"
      fill_and_submit_login(@user)
      current_url.should eq "http://my.sublimevideo.dev/sites"
    end
  end

  context 'user is logged-in without any site' do
    background do
      sign_in_as :user
    end

    scenario 'redirects to /assistant/new-site' do
      go 'my', 'addons'
      current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    end
  end

  context 'user is logged-in with 1 site' do
    background do
      sign_in_as :user_with_site
      @site = @current_user.sites.first
    end

    scenario 'redirects /sites/:token/addons' do
      go 'my', 'addons'
      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    end
  end

  context 'user is logged-in with more than 1 sites' do
    background do
      sign_in_as :user_with_sites
    end

    scenario 'redirects to /sites' do
      go 'my', 'addons'
      current_url.should eq "http://my.sublimevideo.dev/sites"
    end
  end
end

feature 'Choose add-ons' do
  background do
    sign_in_as :user_with_site
    @site = @current_user.sites.first

    @site.reload.billable_items.should have(13).items
    @site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    @site.billable_item_activities.should have(13).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    go 'my', "/sites/#{@site.to_param}/addons"
  end

  scenario 'select radio button add-on' do
    choose "addon_plans_logo_#{@logo_addon_plan_2.name}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(2)

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    page.should have_content 'Your add-ons selection has been confirmed.'

    @site.reload.billable_items.should have(13).items
    @site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item

    @site.billable_item_activities.should have(13 + 2).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item
  end

  scenario 'select checkbox add-on' do
    check "addon_plans_stats_#{@stats_addon_plan_2.name}"
    check "addon_plans_social_sharing_#{@social_sharing_addon_plan_1.name}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(3)

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    page.should have_content 'Your add-ons selection has been confirmed.'

    @site.reload.billable_items.should have(14).items
    @site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'beta').should have(1).item

    @site.billable_item_activities.should have(13 + 3).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'beta').should have(1).item

    go 'my', "/sites/#{@site.to_param}/addons"

    uncheck "addon_plans_stats_#{@stats_addon_plan_2.name}"
    uncheck "addon_plans_social_sharing_#{@social_sharing_addon_plan_1.name}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(3)

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    page.should have_content 'Your add-ons selection has been confirmed.'

    @site.reload.billable_items.should have(13).items
    @site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item

    @site.billable_item_activities.should have(16 + 3).items
    @site.billable_item_activities.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(2).item
    @site.billable_item_activities.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'trial').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'beta').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'canceled').should have(1).item
    @site.billable_item_activities.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'canceled').should have(1).item

  end
end
