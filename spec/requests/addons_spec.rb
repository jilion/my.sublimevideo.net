require 'spec_helper'

feature 'Choose add-ons' do
  background do
    sign_in_as :user
    @site = create(:site, user: @current_user)
    go 'my', "/sites/#{@site.to_param}/addons"
  end

  scenario 'select radio button add-on' do
    @site.reload.addons.active.should be_empty

    choose 'site_addons_logo_no-logo'
    click_button 'Apply changes'

    @site.reload.addons.active.should =~ [@logo_no_logo_addon, @support_standard_addon]
  end

  scenario 'select checkbox add-on' do
    @site.reload.addons.active.should be_empty

    check 'site_addons_stats'
    click_button 'Apply changes'

    @site.reload.addons.active.should =~ [@logo_sublime_addon, @support_standard_addon, @stats_standard_addon]
  end
end
