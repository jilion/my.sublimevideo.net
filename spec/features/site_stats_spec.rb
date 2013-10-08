require 'spec_helper'

feature 'Stats page' do
  background do
    stub_site_stats
    sign_in_as :user
    @site = build(:site, user: @current_user)
    SiteManager.new(@site).create
  end

  scenario 'user dont see the Stats tab' do
    go 'my', "/sites/#{@site.token}/edit"

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.token}/edit"
    page.should have_content 'Settings'
    page.should have_no_link 'Stats'
  end

  context 'user has not activated the stats add-on' do
    scenario 'redirect to /sites' do
      go 'my', "/sites/#{@site.token}/stats"

      current_url.should eq 'http://my.sublimevideo.dev/sites'
    end
  end

  context 'user have the invisible stats add-on plan (default)' do
    scenario 'redirect to /sites' do
      go 'my', "/sites/#{@site.token}/stats"

      current_url.should eq 'http://my.sublimevideo.dev/sites'
    end
  end

  context 'user is subscribed in trial to the stats add-on' do
    background do
      create(:billable_item, site: @site, item: @stats_addon_plan_2, state: 'trial')
    end

    scenario 'display the stats page' do
      go 'my', "/sites/#{@site.token}/edit"
      click_link 'Stats'

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.token}/stats"
    end
  end

  context 'user is subscribed to the stats add-on' do
    background do
      create(:billable_item, site: @site, item: @stats_addon_plan_2, state: 'subscribed')
    end

    scenario 'display the stats page' do
      go 'my', "/sites/#{@site.token}/edit"
      click_link 'Stats'

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.token}/stats"
    end
  end

end
