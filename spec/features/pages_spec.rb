# coding: utf-8
require 'spec_helper'

feature "Terms page" do

  scenario "/terms" do
    go 'my', 'terms'
    page.should have_content('Terms & Conditions')
  end

end

feature "Privacy page" do

  scenario "/privacy" do
    go 'my', 'privacy'
    page.should have_content('Privacy Policy')
  end

end

feature "Help page" do

  describe "Access the help page" do
    context "When the user is logged-in" do
      background do
        sign_in_as :user
      end

      scenario "can access the page directly" do
        go 'my', '/help'
        current_url.should eq "http://my.sublimevideo.dev/help"
      end

      scenario "can access the page via a link in the menu" do
        within '#menu' do
          click_link "help"
        end
        current_url.should eq "http://my.sublimevideo.dev/help"
      end

      scenario "redirect /feedback and /support" do
        go 'my', '/support'
        current_url.should eq "http://my.sublimevideo.dev/help"

        go 'my', '/feedback'
        current_url.should eq "http://my.sublimevideo.dev/feedback"
      end
    end
  end

end

feature "Suspended page" do

  context "logged-in user" do
    background do
      sign_in_as :user
    end

    context "with a non-suspended user" do
      scenario "/suspended" do
        go 'my', 'suspended'

        current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
        page.should have_no_content 'Your account is suspended'
      end
    end

    context "with a suspended user" do
      background do
        @site = build(:site, user: @current_user)
        SiteManager.new(@site).create
        @invoice = create(:failed_invoice, site: @site, last_failed_at: Time.utc(2010,2,10), amount: 1990)
        @transaction = create(:failed_transaction, invoices: [@invoice], error: "Credit Card expired")
        UserManager.new(@current_user).suspend
        @site.reload.should be_suspended
        @current_user.reload.should be_suspended
      end

      scenario "can't visit the edit account page" do
        go 'my', 'account'

        current_url.should eq "http://my.sublimevideo.dev/suspended"
      end
    end
  end

end
