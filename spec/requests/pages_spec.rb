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
        @site = Factory(:site, user: @current_user)
        @current_user.cc_expire_on = 1.month.ago
        @current_user.save(validate: false)
        @current_user.should be_cc_expired
        @invoice     = Factory(:invoice, site: @site, state: 'failed', last_failed_at: Time.utc(2010,2,10), amount: 1990)
        @transaction = Factory(:transaction, invoices: [@invoice], state: 'failed', error: "Credit Card expired")
        @current_user.suspend
        visit "/suspended"
      end

      scenario "suspended page" do
        current_url.should =~ %r(^http://[^/]+/suspended$)

        page.should have_content('Your account is suspended')
        page.should have_content("Your credit card is expired.")
        page.should have_content("Visa ending in 1111")
        page.should have_content("Update credit card")
        page.should have_content("You have to pay the following invoice(s) in order to see your account re-activated:")
        page.should have_content("$19.90 on #{I18n.l(@invoice.created_at, :format => :d_b_Y)}.")
        page.should have_content("Payment failed on #{I18n.l(@invoice.last_failed_at, :format => :minutes_timezone)} with the following error:")
        page.should have_content("\"#{@invoice.last_transaction.error}\"")
      end
    end
  end
end
