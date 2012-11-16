require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'Redirects' do
  background do
    # stats demo site
    site = build(:site)
    Service::Site.new(site).create
    site.update_column(:token, 'ibvjcopp')
  end

  context 'user has no site' do
    background do
      sign_in_as :user
    end

    scenario 'redirect / to /sites/new' do
      go 'my', ''

      current_url.should eq 'http://my.sublimevideo.dev/sites/new'
    end
    scenario 'redirect /video-code-generator to /sites/new' do
      go 'my', 'video-code-generator'

      current_url.should eq 'http://my.sublimevideo.dev/sites/new'
    end

    scenario 'redirect /account/edit to /account' do
      go 'my', 'account/edit'

      current_url.should eq 'http://my.sublimevideo.dev/account'
    end

    scenario 'redirect /card/foo/bar to /account/billing/edit' do
      go 'my', 'card/foo/bar'

      current_url.should eq 'http://my.sublimevideo.dev/account/billing/edit'
    end

    %w[stats sites/stats/demo].each do |page|
      scenario "redirect /#{page} to /stats-demo" do
        go 'my', page

        current_url.should eq 'http://my.sublimevideo.dev/stats-demo'
      end
    end

    scenario 'redirect /support to /help' do
      go 'my', 'support'

      current_url.should eq 'http://my.sublimevideo.dev/help'
    end
  end

  context 'user has a site' do
    background do
      sign_in_as :user_with_site
      @site = @current_user.sites.first
    end

    scenario 'redirect / to /sites' do
      go 'my', ''

      current_url.should eq 'http://my.sublimevideo.dev/sites'
    end

    %w[video-code-generator publish-video].each do |page|
      scenario "redirect /#{page} to /sites/:token/publish-video" do
        go 'my', page

        current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/publish-video"
      end
    end

    scenario 'redirect /sites/stats to /sites' do
      go 'my', 'sites/stats'

      current_url.should eq 'http://my.sublimevideo.dev/sites'
    end

    scenario 'redirect /sites/stats/:site_id to /sites' do
      go 'my', "/sites/#{@site.to_param}/addons"
      check "addon_plans_stats_#{@stats_addon_plan_2.id}"
      click_button 'Confirm selection'
      go 'my', "sites/stats/#{@site.to_param}"

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/stats"
    end
  end
end
