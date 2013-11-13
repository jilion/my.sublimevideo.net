# encoding: utf-8
require 'spec_helper'

feature 'OAuth applications' do
  context 'as a user without a @jilion.com email' do
    background do
      sign_in_as :user

      @application = create(:client_application, user: @current_user)
      @token       = create(:oauth2_token, user: @current_user, client_application: @application)
    end

    describe 'list OAuth applications' do
      scenario 'shows a list of applications' do
        go 'my', '/account/applications'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account'
      end
    end

    describe 'new OAuth applications' do
      scenario 'shows a list of applications' do
        go 'my', '/account/applications/new'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account'
      end
    end

    describe 'edit an OAuth applications' do
      scenario 'shows a list of applications' do
        go 'my', "/account/applications/#{@application.id}/edit"
        expect(current_url).to eq 'http://my.sublimevideo.dev/account'
      end
    end
  end

  context 'as a user with a @jilion.com email' do
    background do
      sign_in_as :user, email: 'remy@jilion.com'

      @application = create(:client_application, user: @current_user)
      @token       = create(:oauth2_token, user: @current_user, client_application: @application)
    end

    describe 'list OAuth applications' do
      scenario 'shows a list of applications' do
        go 'my', '/account/applications'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/applications'

        expect(page).to have_content('Agree2')
      end
    end

    describe 'new OAuth applications' do
      scenario 'shows a list of applications' do
        go 'my', '/account/applications'

        click_link 'Register a new application'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/applications/new'

        fill_in 'Name', with: 'WordPress'
        fill_in 'Url',  with: 'http://wordpress.com'
        click_button 'Register'

        expect(current_url).to eq "http://my.sublimevideo.dev/account/applications/#{ClientApplication.last.id}"
        expect(page).to have_content('WordPress')
      end
    end

    describe 'edit an OAuth applications' do
      scenario 'shows a list of applications' do
        go 'my', '/account/applications'

        click_link 'Edit'

        expect(current_url).to eq "http://my.sublimevideo.dev/account/applications/#{@application.id}/edit"
        expect(page).to have_content('Edit the application “Agree2”')

        fill_in 'Name',         with: 'Agree3'
        fill_in 'Callback url', with: 'http://test.fr'
        click_button 'Update'

        expect(page).to have_content('Agree3')
        expect(page).to have_content('http://test.com')
        expect(page).to have_content('http://test.fr')
      end
    end

    describe 'delete an OAuth applications' do
      scenario 'shows a list of applications' do
        go 'my', '/account/applications'
        expect(page).to have_content('Agree2')

        click_button 'Delete'

        expect(current_url).to match(%r(^http://[^/]+/account/applications$))
        expect(page).to have_no_content('Agree2')
      end
    end
  end

end
