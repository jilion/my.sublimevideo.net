require 'spec_helper'

describe "Pages" do

  feature "Pages:" do
    scenario "terms" do
      visit "/terms"
      page.should have_content('Terms & Conditions')
    end

    scenario "privacy" do
      visit "/privacy"
      page.should have_content('Privacy Policy')
    end

    feature "suspended" do

      feature "non-suspended user" do
        scenario "privacy" do
          sign_in_as :user
          visit "/suspended"

          current_url.should =~ %r(^http://[^/]+/sites$)
          page.should_not have_content('Your account is suspended')
        end
      end

      feature "suspended user" do
        background do
          sign_in_as :user, { :cc_expire_on => 1.month.ago }
          @current_user.cc_expire_on = 1.month.ago
          @current_user.save(:validate => false)
          @current_user.should be_cc_expired
          @site        = Factory(:site, user: @current_user)
          @invoice     = Factory(:invoice, site: @site, state: 'failed', failed_at: Time.utc(2010,2,10))
          @transaction = Factory(:transaction, invoices: [@invoice], state: 'failed', error: "Credit Card expired")
          @current_user.suspend
          @worker.work_off
          visit "/suspended"
        end

        scenario "suspended page" do
          current_url.should =~ %r(^http://[^/]+/suspended$)
          page.should have_content('Your account is suspended')

          page.should have_content("Your credit card is expired.")
          page.should have_content("Visa ending in 1234")
          page.should have_content("Edit credit card")
          # FIXME
          # page.should have_content("$100.00 on January 2010")
          page.should have_content("Charging failed on #{I18n.l(@invoice.failed_at, :format => :minutes_timezone)} with the following error:")
          # FIXME
          # page.should have_content("\"#{@invoice.transactions.failed.last.error}\"")
        end

        scenario "updating credit card" do
          click_link_or_button "Edit credit card"

          VCR.use_cassette('credit_card_visa_validation') do
            fill_in "user_cc_full_name", :with => "John Doe"
            fill_in "user_cc_number", :with => "4111111111111111"
            fill_in "user_cc_verification_value", :with => "111"
            click_button "Update"
          end

          current_url.should =~ %r(^http://[^/]+/suspended$)
        end

        scenario "updating credit card and paying the only failed invoice" do
          click_link_or_button "Edit credit card"

          VCR.use_cassette('credit_card_visa_validation') do
            fill_in "user_cc_full_name", :with => "John Doe"
            fill_in "user_cc_number", :with => "4111111111111111"
            fill_in "user_cc_verification_value", :with => "111"
            click_button "Update"
          end

          current_url.should =~ %r(^http://[^/]+/suspended$)
          # FIXME
          # lambda { click_button "Pay the January 2010 invoice" }.should change(Delayed::Job, :count).by(1)
          current_url.should =~ %r(^http://[^/]+/suspended$)

          VCR.use_cassette "ogone_visa_payment_2000_alias" do
            @worker.work_off
          end

          # FIXME
          # visit '/suspended'
          # current_url.should =~ %r(^http://[^/]+/sites$)
        end

        scenario "updating credit card and paying first failed invoice, then the second failed invoice" do
          @site2        = Factory(:site, user: @current_user)
          @invoice2     = Factory(:invoice, site: @site, state: 'failed', failed_at: Time.utc(2010,2,10))
          @transaction2 = Factory(:transaction, invoices: [@invoice2], state: 'failed', error: "Credit Card invalid")
          @worker.work_off
          
          visit '/suspended'

          # FIXME
          # page.should have_content("$100.00 on January 2010")
          page.should have_content("Charging failed on #{I18n.l(@invoice.failed_at, :format => :minutes_timezone)} with the following error:")
          # FIXME
          # page.should have_content("\"#{@invoice.transactions.failed.last.error}\"")
          # page.should have_content("$100.00 on February 2010")
          page.should have_content("Charging failed on #{I18n.l(@invoice2.failed_at, :format => :minutes_timezone)} with the following error:")
          # FIXME
          # page.should have_content("\"#{@invoice2.transactions.failed.last.error}\"")

          click_link_or_button "Edit credit card"

          VCR.use_cassette('credit_card_visa_validation') do
            fill_in "user_cc_full_name", :with => "John Doe"
            fill_in "user_cc_number", :with => "4111111111111111"
            fill_in "user_cc_verification_value", :with => "111"
            click_button "Update"
          end

          current_url.should =~ %r(^http://[^/]+/suspended$)
          # FIXME
          # page.should have_content("January 2010")
          # page.should have_content("February 2010")
          # lambda { click_button "Pay the January 2010 invoice" }.should change(Delayed::Job, :count).by(1)

          current_url.should =~ %r(^http://[^/]+/suspended$)
          # FIXME
          # lambda { click_button "Pay the February 2010 invoice" }.should change(Delayed::Job, :count).by(1)

          current_url.should =~ %r(^http://[^/]+/suspended$)

          VCR.use_cassette "ogone_visa_payment_2000_alias" do
            @worker.work_off
          end

          # FIXME
          # visit '/suspended'
          # current_url.should =~ %r(^http://[^/]+/sites$)
        end
      end

    end
  end

end