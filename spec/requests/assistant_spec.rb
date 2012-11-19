require 'spec_helper'

feature 'assistant pages' do
  context 'user is logged-in without any site' do
    background do
      sign_in_as :user
      go 'my', ''
    end

    scenario 'redirects to /assistant/new-site' do
      current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
      fill_in 'Domain', with: 'rymai.me'
      click_button 'Next'
      site = @current_user.sites.last

      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/addons"
      page.should have_content 'Site has been successfully registered.'
      page.should have_content 'Choose player add-ons for rymai.me'
      site.current_assistant_step.should eq 'addons'

      choose "addon_plans_logo_#{@logo_addon_plan_2.id}"
      expect { click_button 'Next' }.to change(site.billable_item_activities, :count).by(2)

      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/player"
      page.should have_content 'Your add-ons selection has been confirmed.'
      page.should have_content 'Create a player for rymai.me'
      site.reload.current_assistant_step.should eq 'player'

      fill_in 'Player name', with: 'My awesome player!'
      click_button 'Next'

      site.reload.kits.last.name.should eq 'My awesome player!'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/publish-video"
      page.should have_content 'Publish a video on rymai.me'
      site.reload.current_assistant_step.should eq 'publish_video'

      click_button 'Next'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/summary"
      site.reload.current_assistant_step.should eq 'summary'
    end
  end

  context 'user is logged-in with 1 site on step "addons"' do
    background do
      sign_in_as :user_with_site
      @site = @current_user.sites.first
      @site.update_column(:current_assistant_step, 'addons')
      go 'my', ''
    end

    scenario 'goes to /assistant/:token/addons' do
      page.should have_content 'step 2 of 5'
      click_link 'Finish setup'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{@site.to_param}/addons"
    end

  end

  context 'site has its addons_updated_at set' do
    background do
      sign_in_as :user_with_site
      @site = @current_user.sites.first
      @site.update_column(:addons_updated_at, Time.now)
      go 'my', ''
    end

    scenario 'goes to /assistant/:token/player' do
      page.should have_content 'step 2 of 5'
      click_link 'Finish setup'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{@site.to_param}/player"
    end
  end

  context 'user is logged-in with 1 site on step "player"' do
    background do
      sign_in_as :user_with_site
      @site = @current_user.sites.first
      @site.update_column(:current_assistant_step, 'player')
      go 'my', ''
    end

    scenario 'goes to /assistant/:token/player' do
      page.should have_content 'step 3 of 5'
      click_link 'Finish setup'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{@site.to_param}/player"
    end
  end
end
