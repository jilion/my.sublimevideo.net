# coding: utf-8
require 'spec_helper'

feature "Pusher" do

  describe "/pusher/auth" do
    scenario "with no user logged in" do
      page.driver.post('/pusher/auth', socket_id: '1430.1222084', channel_name: 'presence-token')
      page.driver.status_code.should eql 403
    end

    context "with logged-in user" do
      background do
        sign_in_as :user
      end

      scenario "authorized site token on private channel" do
        site = Factory.create(:site, user: @current_user)
        page.driver.post('/pusher/auth', socket_id: '1427.1223076', channel_name: "presence-#{site.token}")
        page.driver.status_code.should eql 200
      end

      scenario "authorized site token on presence channel" do
        site = Factory.create(:site, user: @current_user)
        page.driver.post('/pusher/auth', socket_id: '1427.1223076', channel_name: "presence-#{site.token}")
        page.driver.status_code.should eql 200
      end

      scenario "un-authorized site token" do
        site = Factory.create(:site)
        page.driver.post('/pusher/auth', socket_id: '1427.1223076', channel_name: "presence-#{site.token}")
        page.driver.status_code.should eql 403
      end

    end
  end
end