require 'spec_helper'

feature 'special /addons page' do
  context 'user is not logged in' do
    background do
      @user = create(:user)
    end

    context 'without any site' do
      scenario 'redirects to /login and then to /assistant/new-site' do
        go 'my', 'addons'
        expect(current_url).to eq "http://my.sublimevideo.dev/login"
        fill_and_submit_login(@user)
        expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
      end
    end

    context 'with 1 site' do
      background do
        @site = build(:site, user: @user)
        SiteManager.new(@site).create
      end

      scenario 'redirects to /login and then to /sites/:token/addons' do
        go 'my', 'addons'
        expect(current_url).to eq "http://my.sublimevideo.dev/login"
        fill_and_submit_login(@user)
        expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
      end
    end
  end

  context 'user is logged-in' do
    context 'without any site' do
      background do
        sign_in_as :user
      end

      scenario 'redirects to /assistant/new-site' do
        go 'my', 'addons'
        expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
      end
    end

    context 'with 1 site' do
      background do
        sign_in_as :user_with_site
        @site = @current_user.sites.by_last_30_days_admin_starts.first
      end

      scenario 'redirects /sites/:token/addons' do
        go 'my', 'addons'
        expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
      end
    end
  end

  context 'user is logged-in with more than 1 sites' do
    background do
      sign_in_as :user_with_sites
      @site = @current_user.sites.by_last_30_days_admin_starts.first
    end

    scenario 'redirects to /sites/:token/addons' do
      go 'my', 'addons'
      expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    end
  end
end

feature 'Add-on subscription shortcut' do
  background do
    sign_in_as :user_with_sites
    @site = @current_user.sites.by_last_30_days_admin_starts.first
  end

  scenario 'redirects to first site addon page' do
    go 'my', "sites/foo/addons/stats"

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons/stats"
  end

  scenario 'redirects to first site addons page' do
    go 'my', "sites/foo/addons/bar"

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
  end

  scenario 'redirects sites/:token/addons/foo to /sites/:token/addons' do
    go 'my', "sites/#{@site.to_param}/addons/foo"

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
  end

  scenario 'redirects sites/:token/addons?h=stats-realtime to /sites/:token/addons/stats' do
    go 'my', "sites/#{@site.to_param}/addons/stats?p=realtime"

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons/stats?p=realtime"
  end

  scenario 'redirects addons/stats to /sites/:token/addons/stats' do
    go 'my', "addons/stats"

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons/stats"
  end
end

feature 'Choose add-ons' do
  background do
    sign_in_as :user_with_site
    @site = @current_user.sites.first

    expect(@site.reload.billable_items.size).to eq(13)
    expect(@site.billable_items.with_item(@classic_design)           .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@flat_design)              .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@light_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@video_player_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@image_viewer_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@controls_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@initial_addon_plan_1)     .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@embed_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@lightbox_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@stats_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@logo_addon_plan_1)        .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@api_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@support_addon_plan_1)     .state('subscribed').size).to eq(1)

    expect(@site.billable_item_activities.size).to eq(13)
    expect(@site.billable_item_activities.with_item(@classic_design)           .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@flat_design)              .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@light_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@video_player_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@image_viewer_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@controls_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@initial_addon_plan_1)     .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@embed_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@lightbox_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@logo_addon_plan_1)        .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@api_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@support_addon_plan_1)     .state('subscribed').size).to eq(1)

    go 'my', "/sites/#{@site.to_param}/addons"
  end

  scenario 'select radio button add-on' do
    choose "addon_plans_logo_#{@logo_addon_plan_2.name}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(2)

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    expect(page).to have_content 'Your add-ons selection has been confirmed.'

    expect(@site.reload.billable_items.size).to eq(13)
    expect(@site.billable_items.with_item(@classic_design)           .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@flat_design)              .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@light_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@video_player_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@controls_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@initial_addon_plan_1)     .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@embed_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@image_viewer_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@lightbox_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@stats_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@api_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@support_addon_plan_1)     .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@logo_addon_plan_2)        .state('trial').size).to eq(1)

    expect(@site.billable_item_activities.size).to eq(13 + 2)
    expect(@site.billable_item_activities.with_item(@classic_design)           .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@flat_design)              .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@light_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@video_player_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@image_viewer_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@controls_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@initial_addon_plan_1)     .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@embed_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@lightbox_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@logo_addon_plan_1)        .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@api_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@support_addon_plan_1)     .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@logo_addon_plan_1)        .state('canceled').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@logo_addon_plan_2)        .state('trial').size).to eq(1)
  end

  scenario 'select checkbox add-on' do
    check "addon_plans_stats_#{@stats_addon_plan_2.name}"
    check "addon_plans_social_sharing_#{@social_sharing_addon_plan_1.name}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(3)

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    expect(page).to have_content 'Your add-ons selection has been confirmed.'

    expect(@site.reload.billable_items.size).to eq(14)
    expect(@site.billable_items.with_item(@classic_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@flat_design)                .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@light_design)               .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@video_player_addon_plan_1)  .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@image_viewer_addon_plan_1)  .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@controls_addon_plan_1)      .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@initial_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@embed_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@lightbox_addon_plan_1)      .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@stats_addon_plan_2)         .state('trial').size).to eq(1)
    expect(@site.billable_items.with_item(@logo_addon_plan_1)          .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@api_addon_plan_1)           .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@support_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@social_sharing_addon_plan_1).state('trial').size).to eq(1)

    expect(@site.billable_item_activities.size).to eq(13 + 3)
    expect(@site.billable_item_activities.with_item(@classic_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@flat_design)                .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@light_design)               .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@video_player_addon_plan_1)  .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@image_viewer_addon_plan_1)  .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@controls_addon_plan_1)      .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@initial_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@embed_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@lightbox_addon_plan_1)      .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@logo_addon_plan_1)          .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@api_addon_plan_1)           .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@support_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_1)         .state('canceled').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_2)         .state('trial').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@social_sharing_addon_plan_1).state('trial').size).to eq(1)

    go 'my', "/sites/#{@site.to_param}/addons"

    uncheck "addon_plans_stats_#{@stats_addon_plan_2.name}"
    uncheck "addon_plans_social_sharing_#{@social_sharing_addon_plan_1.name}"
    expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(3)

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/addons"
    expect(page).to have_content 'Your add-ons selection has been confirmed.'

    expect(@site.reload.billable_items.size).to eq(13)
    expect(@site.billable_items.with_item(@classic_design)           .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@flat_design)              .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@light_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@video_player_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@image_viewer_addon_plan_1).state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@controls_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@initial_addon_plan_1)     .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@embed_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@lightbox_addon_plan_1)    .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@stats_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@logo_addon_plan_1)        .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@api_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_items.with_item(@support_addon_plan_1)     .state('subscribed').size).to eq(1)

    expect(@site.billable_item_activities.size).to eq(16 + 3)
    expect(@site.billable_item_activities.with_item(@classic_design)             .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@flat_design)                .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@light_design)               .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@video_player_addon_plan_1)  .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@image_viewer_addon_plan_1)  .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@controls_addon_plan_1)      .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@initial_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@embed_addon_plan_1)         .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@lightbox_addon_plan_1)      .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_1)         .state('subscribed').size).to eq(2)
    expect(@site.billable_item_activities.with_item(@logo_addon_plan_1)          .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@api_addon_plan_1)           .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@support_addon_plan_1)       .state('subscribed').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_1)         .state('canceled').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_2)         .state('trial').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@social_sharing_addon_plan_1).state('trial').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@stats_addon_plan_2)         .state('canceled').size).to eq(1)
    expect(@site.billable_item_activities.with_item(@social_sharing_addon_plan_1).state('canceled').size).to eq(1)
  end
end
