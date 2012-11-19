require 'spec_helper'

feature 'assistant pages' do
  context 'user is logged-in without any site' do
    background do
      sign_in_as :user
      go 'my', ''
    end

    scenario 'redirects to /sites/new' do
      current_url.should eq "http://my.sublimevideo.dev/sites/new"
      click_button 'Next'
      site = @current_user.sites.last
      site.current_assistant_step.should eq 'addons'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/addons"

      click_button 'Next'
      site.reload.current_assistant_step.should eq 'player'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/player"

      click_button 'Next'
      site.reload.current_assistant_step.should eq 'publish_video'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/publish-video"

      click_link 'Next'
      site.reload.current_assistant_step.should eq 'summary'
      current_url.should eq "http://my.sublimevideo.dev/assistant/#{site.to_param}/summary"
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
