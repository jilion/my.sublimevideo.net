# coding: utf-8
require 'spec_helper'

feature "Terms page" do

  scenario "/terms" do
    go 'my', 'terms'
    expect(page).to have_content('Terms & Conditions')
  end

end

feature "Privacy page" do

  scenario "/privacy" do
    go 'my', 'privacy'
    expect(page).to have_content('Privacy Policy')
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
        expect(current_url).to eq "http://my.sublimevideo.dev/help"
      end

      scenario "can access the page via a link in the menu" do
        within '#menu' do
          click_link "help"
        end
        expect(current_url).to eq "http://my.sublimevideo.dev/help"
      end

      scenario "redirect /feedback and /support" do
        go 'my', '/support'
        expect(current_url).to eq "http://my.sublimevideo.dev/help"

        go 'my', '/feedback'
        expect(current_url).to eq "http://my.sublimevideo.dev/feedback"
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
      expect(UserSupportManager.new(@current_user).level).to eq 'email'
      Sidekiq::Worker.clear_all
      go 'my', '/help'
    end

    describe "new" do
      scenario "has access to the form" do
        expect(page).to have_content 'Use the form below'
        expect(page).to have_selector 'form.new_support_request'
      end

      scenario "submit a valid support request", :vcr do
        fill_in "Subject", with: "SUBJECT"
        fill_in "Description of your issue or question", with: "DESCRIPTION"

        allow(PusherWrapper).to receive(:trigger)
        click_button "Send"
        expect(page).to have_content I18n.t('flash.support_requests.create.notice')
        expect(@current_user.reload.zendesk_id).to be_present
      end

      scenario "submit a support request with an invalid subject" do
        fill_in "Subject", with: ""
        fill_in "Description of your issue or question", with: "DESCRIPTION"
        click_button "Send"

        expect(current_url).to eq "http://my.sublimevideo.dev/help"
        expect(page).to have_content "Subject can't be blank"
        expect(page).to have_no_content I18n.t('flash.support_requests.create.notice')
      end

      scenario "submit a support request with an invalid message" do
        fill_in "Subject", with: "SUBJECT"
        fill_in "Description of your issue or question", with: ""
        click_button "Send"

        expect(current_url).to eq "http://my.sublimevideo.dev/help"
        expect(page).to have_content "Message can't be blank"
        expect(page).to have_no_content I18n.t('flash.support_requests.create.notice')
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

        expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
        expect(page).to have_no_content 'Your account is suspended'
      end
    end

    context "with a suspended user" do
      background do
        @site = build(:site, user: @current_user)
        SiteManager.new(@site).create
        @invoice = create(:failed_invoice, site: @site, last_failed_at: Time.utc(2010,2,10), amount: 1990)
        @transaction = create(:failed_transaction, invoices: [@invoice], error: "Credit Card expired")
        UserManager.new(@current_user).suspend
        expect(@site.reload).to be_suspended
        expect(@current_user.reload).to be_suspended
      end

      scenario "can't visit the edit account page" do
        go 'my', 'account'

        expect(current_url).to eq "http://my.sublimevideo.dev/suspended"
      end

      scenario "can visit the edit credit card page" do
        go 'my', 'account/billing/edit'

        expect(current_url).to eq "http://my.sublimevideo.dev/account/billing/edit"
      end

      scenario "and an expired credit card, should be able to visit the credit card form page" do
        @current_user.cc_expire_on = 1.month.ago
        @current_user.save(validate: false)
        expect(@current_user.reload).to be_cc_expired
        go 'my', 'sites'

        expect(current_url).to eq "http://my.sublimevideo.dev/suspended"

        expect(page).to have_content "Your account is suspended"
        expect(page).to have_content "Your credit card is expired"
        expect(page).to have_content "#{I18n.t('user.credit_card.type.visa')} ending in 1111"
        expect(page).to have_content "Update credit card"
        expect(page).to have_content "Please pay the following invoice in order to reactivate your account:"
        expect(page).to have_content "$19.90 on #{I18n.l(@invoice.created_at, format: :d_b_Y)}."
        expect(page).to have_content "Payment failed on #{I18n.l(@invoice.last_failed_at, format: :minutes_timezone)} with the following error:"
        expect(page).to have_content "\"#{@invoice.last_transaction.error}\""

        click_link "Update credit card"

        expect(current_url).to eq "http://my.sublimevideo.dev/account/billing/edit"
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
        expect(@site.reload).to be_suspended
        expect(@current_user.reload).to be_suspended
      end

      scenario "and a valid credit card with 1 or more failed invoices" do
        ActionMailer::Base.deliveries.clear
        Sidekiq::Worker.clear_all
        go 'my', 'suspended'

        expect(current_url).to eq "http://my.sublimevideo.dev/suspended"

        expect(BillingMailer).to delay(:transaction_succeeded)
        expect(UserMailer).to delay(:account_unsuspended).with(@current_user.id)
        expect(LoaderGenerator).to delay(:update_all_stages!).with(@site.id, deletable: true)
        expect(SettingsGenerator).to delay(:update_all!).with(@site.id)

        click_button I18n.t('invoice.retry_invoices')

        expect(@invoice.reload).to be_paid

        expect(current_url).to eq "http://my.sublimevideo.dev/sites"

        expect(@site.invoices.with_state('failed')).to be_empty
        expect(@site.reload).to be_active
        expect(@current_user.reload).to be_active

        go 'my', 'suspended'
        expect(current_url).to eq "http://my.sublimevideo.dev/sites"
      end
    end

  end
end
