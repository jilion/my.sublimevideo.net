require 'spec_helper'

feature 'Kits page' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user)
    Service::Site.new(@site).create
    go 'my', "/sites/#{@site.to_param}/players"
  end

  scenario 'show the index page' do
    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players"
    page.should have_content 'My player 1'
  end

  scenario 'edit a kit by clicking on its name' do
    click_link 'My player 1'

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players/#{@site.kits.first.to_param}/edit"
  end

  scenario 'edit a kit by clicking on the edit button' do
    click_link 'Edit'

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players/#{@site.kits.first.to_param}/edit"
  end

  scenario 'set a kit as default' do
    @site.kits.create!
    go 'my', "/sites/#{@site.to_param}/players"

    @site.kits.first.should be_default
    page.should have_content 'My player 1'
    page.should have_content 'My player 2'

    click_button 'Set as default'

    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players"
    @site.kits.last.should be_default
  end
end

feature 'New kit' do
  background do
    sign_in_as :user
    @site = build(:site, user: @current_user)
    Service::Site.new(@site).create
    go 'my', "/sites/#{@site.to_param}/players"
    click_link 'New Player'
    current_url.should eq "http://my.sublimevideo.dev/sites/#{@site.to_param}/players/new"
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
end

def last_kit_should_be_created(site, name)
  kit = site.reload.kits.last
  kit.name.should eq name

  current_url.should eq "http://my.sublimevideo.dev/sites/#{site.to_param}/players"
  page.should have_content 'Player has been successfully created.'
end