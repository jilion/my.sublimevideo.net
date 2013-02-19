require 'spec_helper'

feature 'Kits page' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user)
    SiteManager.new(@site).create
    go 'my', "/sites/#{@site.to_param}/players"
  end

  scenario 'show the index page' do
    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players"
    page.should have_content 'Default player'
  end

  scenario 'edit a kit by clicking on its name' do
    click_link 'Default player'

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players/#{@site.kits.first.to_param}/edit"
  end

  scenario 'edit a kit by clicking on the edit button' do
    click_link 'Edit'

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players/#{@site.kits.first.to_param}/edit"
  end

  scenario 'set a kit as default' do
    @site.kits.create!(name: 'Funky player')
    go 'my', "/sites/#{@site.to_param}/players"

    @site.kits.first.should be_default
    page.should have_content 'Default player'
    page.should have_content 'Funky player'

    click_button 'Set as default'

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players"
    @site.kits.last.should be_default
  end
end

feature 'New kit' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user)
    SiteManager.new(@site).create
    go 'my', "/sites/#{@site.to_param}/players"
    click_link 'New Player'
    current_url.should =~ %r{http://[^/]+/sites/#{@site.to_param}/players/new}
  end

  scenario 'with no name' do
    fill_in 'Player name', with: ''
    click_button 'Save'

    page.should have_content "Name can't be blank"
  end

  scenario 'with a name' do
    fill_in 'Player name', with: 'My awesome player!'
    click_button 'Save'

    last_kit_should_be_created(@site, 'My awesome player!')
  end

  scenario 'chooses a design update data-settings', :js do
    find('video#standard')['data-settings'].should include 'player-kit: 1'

    select 'Flat', from: 'Player design:'
    sleep 1
    find('video#standard')['data-settings'].should include 'player-kit: 2'

    select 'Light', from: 'Player design:'
    sleep 1
    find('video#standard')['data-settings'].should include 'player-kit: 3'
  end

  scenario 'chooses a design reload partial but keeps modified settings', :js do
    click_link 'Basic Player settings'
    find('#kit_setting-initial-overlay_enable[value="1"]').should be_checked
    uncheck 'kit_setting-initial-overlay_enable'
    select 'Flat', from: 'Player design:'
    sleep 1
    find('#kit_setting-initial-overlay_enable[value="1"]').should_not be_checked
  end

  scenario 'sharing settings are not visible' do
    page.should have_no_content 'Sharing settings'
  end

  describe 'With the sharing add-on' do
    background do
      go 'my', "/sites/#{@site.to_param}/addons"
      check "addon_plans_social_sharing_#{@social_sharing_addon_plan_1.name}"
      expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(1)
      go 'my', "/sites/#{@site.to_param}/players"
      click_link 'New Player'
    end

    scenario 'sharing settings are visible' do
      page.should have_content 'Sharing settings'
    end
  end
end

def last_kit_should_be_created(site, name)
  kit = site.reload.kits.last
  kit.name.should eq name

  current_url.should eq "http://my.sublimevideo.dev/sites/#{site.to_param}/players"
  page.should have_content 'Player has been successfully created.'
end
