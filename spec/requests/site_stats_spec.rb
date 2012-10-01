require 'spec_helper'

feature 'Stats page' do
  background do
    sign_in_as :user
    @site = create(:site, user: @current_user)
  end

  scenario 'user dont see the Stats tab' do
    go 'my', "/sites/#{@site.token}/edit"

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.token}/edit"
    page.should have_content 'Settings'
    page.should have_no_content 'Stats'
  end

  context 'user has not activated the stats add-on' do
    scenario 'redirect to /sites' do
      go 'my', "/sites/#{@site.token}/stats"

      current_url.should eq 'http://my.sublimevideo.dev/sites'
    end
  end

  context 'user has the stats add-on inactive' do
    background do
      create(:inactive_addonship, site: @site, addon: @stats_standard_addon)
    end

    scenario 'redirect to /sites' do
      go 'my', "/sites/#{@site.token}/stats"

      current_url.should eq 'http://my.sublimevideo.dev/sites'
    end
  end

  context 'user has is subscribed in trial to the stats add-on' do
    background do
      create(:trial_addonship, site: @site, addon: @stats_standard_addon)
    end

    scenario 'display the stats page' do
      go 'my', "/sites/#{@site.token}/edit"
      click_link 'Stats'

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.token}/stats"
    end
  end

  context 'user has is subscribed to the stats add-on' do
    background do
      create(:subscribed_addonship, site: @site, addon: @stats_standard_addon)
    end

    scenario 'display the stats page' do
      go 'my', "/sites/#{@site.token}/edit"
      click_link 'Stats'

      current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.token}/stats"
    end
  end

end
