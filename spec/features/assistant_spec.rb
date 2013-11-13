require 'spec_helper'

feature 'assistant pages' do
  background { allow(SiteAdminStat).to receive(:total_admin_starts) { 0 } }

  context 'user is logged-in without any site' do
    background do
      sign_in_as :user
      go 'my', ''
    end

    scenario 'redirects to /assistant/new-site' do
      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
      fill_in 'Main domain', with: 'rymai.me'
      click_button 'Next'
      site = @current_user.sites.last

      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/addons"
      expect(page).to have_content 'Site has been successfully registered.'
      expect(page).to have_content 'Choose player add-ons for rymai.me'
      expect(site.current_assistant_step).to eq 'addons'

      choose "addon_plans_logo_#{@logo_addon_plan_2.name}"
      expect { click_button 'Next' }.to change(site.billable_item_activities, :count).by(2)

      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/player"
      expect(page).to have_content 'Your add-ons selection has been confirmed.'
      expect(page).to have_content 'Create a player for rymai.me'
      expect(site.reload.current_assistant_step).to eq 'player'

      fill_in 'Player name', with: 'My awesome player!'
      click_button 'Next'

      expect(site.reload.kits.last.name).to eq 'My awesome player!'
      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/publish-video"
      expect(page).to have_content 'Publish a video on rymai.me'
      expect(site.reload.current_assistant_step).to eq 'publish_video'

      click_button 'Next'
      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/summary"
      expect(site.reload.current_assistant_step).to eq 'summary'
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
      expect(page).to have_content 'step 2 of 5'
      click_link 'Finish setup'
      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/#{@site.to_param}/addons"
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
      expect(page).to have_content 'step 2 of 5'
      click_link 'Finish setup'
      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/#{@site.to_param}/player"
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
      expect(page).to have_content 'step 3 of 5'
      click_link 'Finish setup'
      expect(current_url).to eq "http://my.sublimevideo.dev/assistant/#{@site.to_param}/player"
    end
  end

  context 'user is logged-in' do
    background do
      sign_in_as :user_with_site
      @site = @current_user.sites.first
    end

    scenario 'redirects from/assistant/:token/summary to /sites' do
      go 'my', "assistant/#{@site.to_param}/summary"
      expect(current_url).to eq "http://my.sublimevideo.dev/sites"
    end
  end
end
