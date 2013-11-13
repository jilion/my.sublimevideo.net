require 'spec_helper'

feature 'Kits page' do
  background do
    sign_in_as :user_with_site
    @site = @current_user.sites.last
    go 'my', "/sites/#{@site.to_param}/players"
  end

  scenario 'show the index page' do
    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players"
    expect(page).to have_content 'Default player'
  end

  scenario 'edit a kit by clicking on its name' do
    click_link 'Default player'

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players/#{@site.kits.first.to_param}/edit"
  end

  scenario 'edit a kit by clicking on the edit button' do
    click_link 'Edit'

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players/#{@site.kits.first.to_param}/edit"
  end

  scenario 'set a kit as default' do
    @site.kits.create!(name: 'Funky player')
    go 'my', "/sites/#{@site.to_param}/players"

    expect(@site.kits.first).to be_default
    expect(page).to have_content 'Default player'
    expect(page).to have_content 'Funky player'

    click_button 'Set as default'

    expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players"
    expect(@site.kits.last).to be_default
  end
end

feature 'New kit' do
  background do
    sign_in_as :user_with_site
    @site = @current_user.sites.last
    go 'my', "/sites/#{@site.to_param}/players"
    click_link 'New Player'
    expect(current_url).to match(%r{http://[^/]+/sites/#{@site.to_param}/players/new})
  end

  scenario 'with no name' do
    fill_in 'Player name', with: ''
    click_button 'Save'

    expect(page).to have_content "Name can't be blank"
  end

  scenario 'with a name' do
    fill_in 'Player name', with: 'My awesome player!'
    click_button 'Save'

    last_kit_should_be_created(@site, 'My awesome player!')
  end

  scenario 'chooses a design update data-settings', :js do
    expect(find('video#standard')['data-settings']).to include 'player-kit: 1'

    select 'Flat', from: 'Player design:'
    sleep 1
    expect(find('video#standard')['data-settings']).to include 'player-kit: 2'

    select 'Light', from: 'Player design:'
    sleep 1
    expect(find('video#standard')['data-settings']).to include 'player-kit: 3'
  end

  scenario 'chooses a design reload partial but keeps modified settings', :js do
    click_link 'Basic Player settings'
    expect(find('#kit_setting-initial-overlay_enable[value="1"]')).to be_checked
    uncheck 'kit_setting-initial-overlay_enable'
    expect(find('#kit_setting-initial-overlay_enable[value="1"]')).not_to be_checked
    select 'Flat', from: 'Player design:'
    sleep 1
    expect(find('#kit_setting-initial-overlay_enable[value="1"]')).not_to be_checked
  end

  scenario 'sharing settings are not visible' do
    expect(page).to have_no_content 'Sharing settings'
  end

  describe 'With the sharing add-on' do
    background do
      go 'my', "/sites/#{@site.to_param}/addons"
      check "addon_plans_social_sharing_#{@social_sharing_addon_plan_1.name}"
      expect { click_button 'Confirm selection' }.to change(@site.billable_item_activities, :count).by(1)
      expect(@site.subscribed_to?(@social_sharing_addon_plan_1)).to be_truthy
      go 'my', "/sites/#{@site.to_param}/players"
      click_link 'New Player'
    end

    scenario 'sharing settings are visible' do
      expect(page).to have_content 'Sharing settings'
    end
  end
end

def last_kit_should_be_created(site, name)
  kit = site.reload.kits.last
  expect(kit.name).to eq name

  expect(current_url).to eq "http://my.sublimevideo.dev/sites/#{site.to_param}/players"
  expect(page).to have_content 'Player has been successfully created.'
end
