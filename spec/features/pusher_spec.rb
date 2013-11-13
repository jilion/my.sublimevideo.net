# coding: utf-8
require 'spec_helper'

feature "Pusher" do
  describe "/pusher/auth" do
    scenario "with no user logged in" do
      page.driver.post('http://my.sublimevideo.dev/pusher/auth', socket_id: '1430.1222084', channel_name: 'private-token')
      expect(page.driver.status_code).to eql 403
    end

    context "with logged-in user" do
      background do
        sign_in_as :user
      end

      scenario "authorized site token on private channel" do
        site = create(:site, user: @current_user)
        page.driver.post('http://my.sublimevideo.dev/pusher/auth', socket_id: '1427.1223076', channel_name: "private-#{site.token}")
        expect(page.driver.status_code).to eql 200
      end

      scenario "authorized site token on presence channel" do
        site = create(:site, user: @current_user)
        page.driver.post('http://my.sublimevideo.dev/pusher/auth', socket_id: '1427.1223076', channel_name: "private-#{site.token}")
        expect(page.driver.status_code).to eql 200
      end

      scenario "un-authorized site token" do
        site = create(:site)
        page.driver.post('http://my.sublimevideo.dev/pusher/auth', socket_id: '1427.1223076', channel_name: "private-#{site.token}")
        expect(page.driver.status_code).to eql 403
      end

    end
  end
end
