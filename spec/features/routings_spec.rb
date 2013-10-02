require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'Redirects' do
  background do
    # stats demo site
    site = build(:site)
    SiteManager.new(site).create
    site.update_column(:token, 'ibvjcopp')
  end

  context 'user has no site' do
    background do
      sign_in_as :user
    end

    scenario 'redirect / to /assistant/new-site' do
      go 'my', ''

      current_url.should eq 'http://my.sublimevideo.dev/assistant/new-site'
    end
    scenario 'redirect /video-code-generator to /assistant/new-site' do
      go 'my', 'video-code-generator'

      current_url.should eq 'http://my.sublimevideo.dev/assistant/new-site'
    end

    scenario 'redirect /account/edit to /account' do
      go 'my', 'account/edit'

      current_url.should eq 'http://my.sublimevideo.dev/account'
    end

    scenario 'redirect /card/foo/bar to /account/billing/edit' do
      go 'my', 'card/foo/bar'

      current_url.should eq 'http://my.sublimevideo.dev/account/billing/edit'
    end

    scenario "redirect /stats to /stats-demo" do
      go 'my', 'stats'

      current_url.should eq 'http://my.sublimevideo.dev/stats-demo'
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
      scenario "redirect /#{page} to /sites/:token/videos/new" do
        go 'my', page

        current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/videos/new"
      end
    end

    scenario 'redirect /sites/:site_id/publish-video to /sites/:site_id/videos/new' do
      go 'my', "/sites/#{@site.to_param}/publish-video"

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/videos/new"
    end
  end
end
