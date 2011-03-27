require 'spec_helper'

feature "Credit cards" do

  feature "update" do

    context "user has no credit card" do
      background do
        sign_in_as :user, :without_cc => true
        @current_user.should_not be_credit_card
      end

      scenario "new credit card" do
        click_link(@current_user.full_name)
        current_url.should =~ %r(^http://[^/]+/account/edit$)

        page.should_not have_content("Add a credit card")
        page.should_not have_content("Update credit card")

        visit "/card/edit"

        current_url.should =~ %r(^http://[^/]+/account/edit$)
      end
    end

    context "user already has a credit card" do
      background do
        sign_in_as :user
        @current_user.should be_credit_card
      end

      scenario "successfully (visa)" do
        click_link(@current_user.full_name)
        current_url.should =~ %r(^http://[^/]+/account/edit$)

        click_link("Update credit card")
        current_url.should =~ %r(^http://[^/]+/card/edit$)

        set_credit_card
        VCR.use_cassette('ogone/credit_card_visa_validation') { click_button "Update" }

        should_save_credit_card_successfully
      end

      scenario "successfully (master)" do
        click_link(@current_user.full_name)
        current_url.should =~ %r(^http://[^/]+/account/edit$)

        click_link("Update credit card")
        current_url.should =~ %r(^http://[^/]+/card/edit$)

        set_credit_card(type: 'master')
        VCR.use_cassette('ogone/credit_card_master_validation') { click_button "Update" }

        sign_out
        sign_in_as :user
        visit '/account/edit'

        page.should have_content "MasterCard"
        page.should have_content '9999'
      end
      
      scenario "entering a 3-D Secure credit card with a succeeding identification" do
        click_link(@current_user.full_name)
        current_url.should =~ %r(^http://[^/]+/account/edit$)

        click_link("Update credit card")
        current_url.should =~ %r(^http://[^/]+/card/edit$)

        set_credit_card(d3d: true)
        VCR.use_cassette('ogone/3ds_authorization') { click_button "Update" }

        # fake payment succeeded callback (and thus skip the d3d redirection)
        VCR.use_cassette('ogone/void_authorization') { @current_user.process_cc_authorize_and_save("PAYID" => "1234", "STATUS" => "5") }
        @current_user.cc_type.should == 'visa'
        @current_user.cc_last_digits.should == '1111'
        @current_user.cc_type.should be_present

        visit '/account/edit'

        page.should have_content "Visa"
        page.should have_content '1111'
      end
      
      scenario "entering a 3-D Secure credit card with a failing identification" do
        click_link(@current_user.full_name)
        current_url.should =~ %r(^http://[^/]+/account/edit$)

        click_link("Update credit card")
        current_url.should =~ %r(^http://[^/]+/card/edit$)

        set_credit_card(d3d: true, type: 'master')
        VCR.use_cassette('ogone/3ds_authorization') { click_button "Update" }

        # fake payment succeeded callback (and thus skip the d3d redirection)
        @current_user.process_cc_authorize_and_save("PAYID" => "1234", "STATUS" => "0")
        
        @current_user.reload
        @current_user.cc_type.should == 'visa'
        @current_user.cc_last_digits.should == '1111'

        visit '/account/edit'
        page.should have_content 'Visa'
        page.should have_content '1111'
      end

      scenario "with a failed attempt first" do
        click_link @current_user.full_name
        current_url.should =~ %r(^http://[^/]+/account/edit$)
        click_link "Update credit card"

        current_url.should =~ %r(^http://[^/]+/card/edit$)
        click_button "Update"

        current_url.should =~ %r(^http://[^/]+/card$)
        page.should have_content "Name on card can't be blank"
        page.should have_content "Card number is invalid"
        page.should have_content "Expiration date expired"
        page.should have_content "CSC is required"

        set_credit_card
        VCR.use_cassette('ogone/credit_card_visa_validation') { click_button "Update" }

        should_save_credit_card_successfully
      end
    end

  end
  
end

def should_save_credit_card_successfully(type='visa')
  current_url.should =~ %r(^http://[^/]+/account/edit$)
  page.should have_content "Your credit card information was successfully (and securely) saved."
  page.should have_content type == 'visa' ? 'Visa' : "MasterCard"
  page.should have_content type == 'visa' ? '1111' : '9999'
end