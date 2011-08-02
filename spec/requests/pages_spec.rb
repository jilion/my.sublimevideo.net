require 'spec_helper'

feature "Pages" do

  scenario "/terms" do
    visit "/terms"
    page.should have_content('Terms & Conditions')
  end

  scenario "/privacy" do
    visit "/privacy"
    page.should have_content('Privacy Policy')
  end

  context "logged-in user" do
    background do
      create_plans
      sign_in_as :user
    end

    context "with a non-suspended user" do
      scenario "/suspended" do
        create_plans
        visit "/suspended"

        current_url.should =~ %r(^http://[^/]+/sites/new$)
        page.should_not have_content('Your account is suspended')
      end
    end

    context "with a suspended user" do
      background do
        @site        = FactoryGirl.create(:site, user: @current_user)
        @site.pending_plan_started_at = Time.now.utc
        @site.pending_plan_cycle_started_at = Time.now.utc
        @site.pending_plan_cycle_ended_at = Time.now.utc
        @site.save!(validate: false)
        @invoice     = FactoryGirl.create(:invoice, site: @site, state: 'failed', last_failed_at: Time.utc(2010,2,10), amount: 1990)
        @transaction = FactoryGirl.create(:transaction, invoices: [@invoice], state: 'failed', error: "Credit Card expired")
        @current_user.suspend
        @site.reload.should be_suspended
        @current_user.reload.should be_suspended
        visit "/suspended"
      end

      scenario "can't visit the edit account page" do
        visit "/account/edit"
        current_url.should =~ %r(^http://[^/]+/suspended$)
      end

      scenario "can visit the edit credit card page" do
        visit "/card/edit"
        current_url.should =~ %r(^http://[^/]+/card/edit$)
      end

      scenario "and an expired credit card, should be able to visit the credit card form page" do
        @current_user.cc_expire_on = 1.month.ago
        @current_user.save(validate: false)
        @current_user.reload.should be_cc_expired
        visit "/sites"

        current_url.should =~ %r(^http://[^/]+/suspended$)

        page.should have_content('Your account is suspended')
        page.should have_content("This credit card is expired")
        page.should have_content("Visa ending in 1111")
        page.should have_content("Expired on:")
        page.should have_content("Update credit card")
        page.should have_content("Please pay the following invoice in order to reactivate your account:")
        page.should have_content("$19.90 on #{I18n.l(@invoice.created_at, :format => :d_b_Y)}.")
        page.should have_content("Payment failed on #{I18n.l(@invoice.last_failed_at, :format => :minutes_timezone)} with the following error:")
        page.should have_content("\"#{@invoice.last_transaction.error}\"")

        click_link "Update credit card"

        current_url.should =~ %r(^http://[^/]+/card/edit$)
      end

      scenario "with 1 or more failed invoices" do
        current_url.should =~ %r(^http://[^/]+/suspended$)

        VCR.use_cassette('ogone/visa_payment_acceptance') { click_button I18n.t('site.invoices.retry_invoices') }

        current_url.should =~ %r(http://[^/]+/sites)

        @site.invoices.failed.should be_empty
        @site.reload.should be_active
        @current_user.reload.should be_active

        visit "/suspended"
        current_url.should =~ %r(http://[^/]+/sites)
      end

    end
  end
end
