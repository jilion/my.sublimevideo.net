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

      scenario "can visit the edit credit card page" do
        go 'my', 'account/billing/edit'

        current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"
      end

      scenario "and an expired credit card, should be able to visit the credit card form page" do
        @current_user.cc_expire_on = 1.month.ago
        @current_user.save(validate: false)
        @current_user.reload.should be_cc_expired
        go 'my', 'sites'

        current_url.should eq "http://my.sublimevideo.dev/suspended"

        page.should have_content "Your account is suspended"
        page.should have_content "Your credit card is expired"
        page.should have_content "#{I18n.t('user.credit_card.type.visa')} ending in 1111"
        page.should have_content "Update credit card"
        page.should have_content "Please pay the following invoice in order to reactivate your account:"
        page.should have_content "$19.90 on #{I18n.l(@invoice.created_at, format: :d_b_Y)}."
        page.should have_content "Payment failed on #{I18n.l(@invoice.last_failed_at, format: :minutes_timezone)} with the following error:"
        page.should have_content "\"#{@invoice.last_transaction.error}\""

        click_link "Update credit card"

        current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"
      end
    end

  end

  context "logged-in user with aliased cc", :vcr do
    background do
      sign_in_as :user_with_aliased_cc
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

      scenario "and a valid credit card with 1 or more failed invoices" do
        ActionMailer::Base.deliveries.clear
        Sidekiq::Worker.clear_all
        go 'my', 'suspended'

        current_url.should eq "http://my.sublimevideo.dev/suspended"

        UserMailer.should delay(:account_unsuspended).with(@current_user.id)
        LoaderGenerator.should delay(:update_all_stages!).with(@site.id, deletable: true)
        SettingsGenerator.should delay(:update_all!).with(@site.id)

        click_button I18n.t('invoice.retry_invoices')

        @invoice.reload.should be_paid

        current_url.should eq "http://my.sublimevideo.dev/sites"

        @site.invoices.with_state('failed').should be_empty
        @site.reload.should be_active
        @current_user.reload.should be_active

        go 'my', 'suspended'
        current_url.should eq "http://my.sublimevideo.dev/sites"
      end
    end

  end
end
