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

  context "user has the 'email' support level" do
    background do
      sign_in_as :user
      site = build(:site, user: @current_user)
      SiteManager.new(site).create
      go 'my', "/sites/#{site.to_param}/addons"
      choose "addon_plans_logo_#{@logo_addon_plan_2.name}"
      expect { click_button 'Confirm selection' }.to change(site.billable_item_activities, :count).by(2)
      UserSupportManager.new(@current_user).level.should eq 'email'
      Sidekiq::Worker.clear_all
      go 'my', '/help'
    end

    describe "new" do
      scenario "has access to the form" do
        page.should have_content 'Use the form below'
        page.should have_selector 'form.new_support_request'
      end

      scenario "submit a valid support request" do
        fill_in "Subject", with: "SUBJECT"
        fill_in "Description of your issue or question", with: "DESCRIPTION"

        PusherWrapper.stub(:trigger)
        VCR.use_cassette("zendesk_wrapper/create_ticket") do
          click_button "Send"
        end
        page.should have_content I18n.t('flash.support_requests.create.notice')
        @current_user.reload.zendesk_id.should be_present
      end

      scenario "submit a support request with an invalid subject" do
        fill_in "Subject", with: ""
        fill_in "Description of your issue or question", with: "DESCRIPTION"
        click_button "Send"

        current_url.should eq "http://my.sublimevideo.dev/help"
        page.should have_content "Subject can't be blank"
        page.should have_no_content I18n.t('flash.support_requests.create.notice')
      end

      scenario "submit a support request with an invalid message" do
        fill_in "Subject", with: "SUBJECT"
        fill_in "Description of your issue or question", with: ""
        click_button "Send"

        current_url.should eq "http://my.sublimevideo.dev/help"
        page.should have_content "Message can't be blank"
        page.should have_no_content I18n.t('flash.support_requests.create.notice')
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
        @site.pending_plan_started_at = Time.now.utc
        @site.pending_plan_cycle_started_at = Time.now.utc
        @site.pending_plan_cycle_ended_at = Time.now.utc
        @site.save!(validate: false)
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

      scenario "and a valid credit card with 1 or more failed invoices" do
        ActionMailer::Base.deliveries.clear
        Sidekiq::Worker.clear_all
        go 'my', 'suspended'

        current_url.should eq "http://my.sublimevideo.dev/suspended"

        VCR.use_cassette('ogone/visa_payment_acceptance') do
          BillingMailer.should delay(:transaction_succeeded)
          UserMailer.should delay(:account_unsuspended).with(@current_user.id)
          LoaderGenerator.should delay(:update_all_stages!).with(@site.id, deletable: true)
          SettingsGenerator.should delay(:update_all!).with(@site.id)

          click_button I18n.t('invoice.retry_invoices')
        end
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