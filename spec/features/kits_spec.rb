require 'spec_helper'

feature 'Kits page' do
  background do
    sign_in_as :user_with_site
    @site = @current_user.sites.last
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
    sign_in_as :user_with_site
    @site = @current_user.sites.last
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

  pending 'chooses a design reload partial but keeps modified settings', :js do
    click_link 'Basic Player settings'
    find('#kit_setting-initial-overlay_enable[value="1"]').should be_checked
    uncheck 'kit_setting-initial-overlay_enable'
    find('#kit_setting-initial-overlay_enable[value="1"]').should_not be_checked
    select 'Flat', from: 'Player design:'
    sleep 1
    find('#kit_setting-initial-overlay_enable[value="1"]').should_not be_checked
  end

  scenario 'sharing settings are visible' do
    page.should have_content 'Sharing settings'
  end
end

def last_kit_should_be_created(site, name)
  kit = site.reload.kits.last
  kit.name.should eq name

  current_url.should eq "http://my.sublimevideo.dev/sites/#{site.to_param}/players"
  page.should have_content 'Player has been successfully created.'
end
