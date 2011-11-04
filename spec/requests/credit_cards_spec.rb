require 'spec_helper'

feature "Credit cards update" do

  context "user has no credit card" do
    background do
      sign_in_as :user, :without_cc => true
      @current_user.should_not be_credit_card
    end

    scenario "successfully" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account$)

      page.should have_content("Register credit card")

      @current_user.cc_type.should be_nil
      @current_user.cc_last_digits.should be_nil

      click_link("Register credit card")
      current_url.should =~ %r(^http://[^/]+/card/edit$)

      set_credit_card(type: 'master')
      VCR.use_cassette('ogone/credit_card_visa_validation') { click_button "Register" }

      @current_user.reload.cc_type.should eql 'master'
      @current_user.cc_last_digits.should eql '9999'
      should_save_credit_card_successfully(type: 'master')

      page.should have_content I18n.t('flash.credit_cards.update.notice')
      page.should have_content "MasterCard"
      page.should have_content '9999'
    end
  end

  context "user already has a credit card" do
    background do
      sign_in_as :user
      @current_user.should be_credit_card
    end

    scenario "successfully" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account$)

      @current_user.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '1111'
      page.should have_content "Visa"
      page.should have_content '1111'

      click_link("Update credit card")
      current_url.should =~ %r(^http://[^/]+/card/edit$)

      set_credit_card(type: 'master')
      VCR.use_cassette('ogone/credit_card_visa_validation') { click_button "Update" }

      @current_user.reload.cc_type.should == 'master'
      @current_user.cc_last_digits.should == '9999'
      should_save_credit_card_successfully(type: 'master')

      page.should have_content I18n.t('flash.credit_cards.update.notice')
      page.should have_content "MasterCard"
      page.should have_content '9999'
    end

    scenario "successfully 3-D Secure credit card with a succeeding identification" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account$)

      @current_user.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '1111'
      page.should have_content "Visa"
      page.should have_content '1111'

      click_link("Update credit card")
      current_url.should =~ %r(^http://[^/]+/card/edit$)

      set_credit_card(d3d: true)
      VCR.use_cassette('ogone/3ds_authorization') { click_button "Update" }
      @current_user.reload.pending_cc_type.should == 'visa'
      @current_user.pending_cc_last_digits.should == '0002'

      page.should have_content "Please click on the \"Continue\" button to continue the processing of your 3-D secure transaction."

      # fake payment succeeded callback (and thus skip the d3d redirection)
      VCR.use_cassette('ogone/void_authorization') { @current_user.process_credit_card_authorization_response("PAYID" => "1234", "STATUS" => "5") }
      @current_user.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '0002'
      @current_user.pending_cc_type.should be_nil
      @current_user.pending_cc_last_digits.should be_nil

      visit '/account'

      page.should have_content I18n.t('flash.credit_cards.update.notice')
      page.should have_content "Visa"
      page.should have_content '0002'
    end

    scenario "waiting 3-D Secure credit card" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account$)

      @current_user.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '1111'
      page.should have_content "Visa"
      page.should have_content '1111'

      click_link("Update credit card")
      current_url.should =~ %r(^http://[^/]+/card/edit$)

      set_credit_card(d3d: true)
      VCR.use_cassette('ogone/3ds_authorization') { click_button "Update" }
      @current_user.reload.pending_cc_type.should == 'visa'
      @current_user.pending_cc_last_digits.should == '0002'


      # fake payment waiting callback (and thus skip the d3d redirection)
      VCR.use_cassette('ogone/void_authorization') { @current_user.process_credit_card_authorization_response("PAYID" => "1234", "STATUS" => "51") }
      @current_user.reload.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '1111'

      visit '/account'
      @current_user.pending_cc_type.should == 'visa'
      @current_user.pending_cc_last_digits.should == '0002'

      page.should have_content "Visa"
      page.should have_content '1111'
      page.should have_content "Update credit card"
    end

    scenario "entering a 3-D Secure credit card with a failing identification" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account$)

      @current_user.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '1111'
      page.should have_content "Visa"
      page.should have_content '1111'

      click_link("Update credit card")
      current_url.should =~ %r(^http://[^/]+/card/edit$)

      set_credit_card(d3d: true)
      VCR.use_cassette('ogone/3ds_authorization') { click_button "Update" }
      @current_user.reload.pending_cc_type.should == 'visa'
      @current_user.pending_cc_last_digits.should == '0002'

      # fake payment failed callback (and thus skip the d3d redirection)
      @current_user.process_credit_card_authorization_response("PAYID" => "1234", "STATUS" => "0")

      @current_user.reload.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '1111'
      @current_user.pending_cc_type.should == 'visa'
      @current_user.pending_cc_last_digits.should == '0002'

      visit '/account'

      should_save_credit_card_successfully
    end

    scenario "with a failed attempt first" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account$)

      @current_user.cc_type.should == 'visa'
      @current_user.cc_last_digits.should == '1111'
      page.should have_content "Visa"
      page.should have_content '1111'

      click_link("Update credit card")
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

def should_save_credit_card_successfully(type='visa')
  current_url.should =~ %r(^http://[^/]+/account$)
  page.should have_content I18n.t('flash.credit_cards.update.notice')
  page.should have_content type == 'visa' ? 'Visa' : "MasterCard"
  page.should have_content type == 'visa' ? '1111' : '9999'
end