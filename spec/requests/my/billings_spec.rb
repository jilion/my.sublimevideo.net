require 'spec_helper'

feature "Access the account page" do

  context "When the user is not logged-in" do
    background do
      create_user(user: {})
    end

    scenario "is redirected to log in page" do
      go 'my', 'account'

      current_url.should eq "http://www.sublimevideo.dev/?p=login"
    end
  end

  context "When the user is logged-in" do
    background do
      sign_in_as :user
    end

    scenario "can access the page directly" do
      go 'my', 'account'

      current_url.should eq "http://my.sublimevideo.dev/account"
    end

    scenario "can access the page via a link in the menu" do
      within '#menu' do
        click_link @current_user.name

        current_url.should eq "http://my.sublimevideo.dev/account"
      end
    end
  end

end

feature "Credentials update" do

  context "When the user is logged-in" do
    background do
      sign_in_as :user
      go 'my', 'account'
    end

    scenario "It's possible to update email" do
      within '#edit_credentials' do
        fill_in "Email", with: "zeno@jilion.com"

        click_button "Update"
      end

      fill_in "Current password", with: '123456'
      click_button "Done"

      User.find(@current_user.id).email.should eq "zeno@jilion.com"
    end

    scenario "It's possible to update password" do
      email = @current_user.email
      within '#edit_credentials' do
        fill_in "New password", with: "654321"
        click_button "Update"
      end

      fill_in "Current password", with: '123456'
      click_button "Done"
      current_url.should eq "http://www.sublimevideo.dev/?p=login"

      fill_in 'Email',    with: email
      fill_in 'Password', with: '654321'
      click_button 'Login'

      current_url.should eq "http://my.sublimevideo.dev/sites/new"
    end
  end

end

feature "'More info' update" do

  context "When the user is logged-in" do
    background do
      sign_in_as :user, billing_address_1: ''
      go 'my', 'account'
    end

    scenario "It's possible to update billing_country and billing_postal_code directly from the edit account page" do
      within '#edit_more_info' do
        fill_in "Name",               with: "Bob Doe"
        fill_in "Zip or Postal Code", with: "91470"
        select  "France",             from: "Country"
        fill_in "Company name",       with: "Jilion"
        select  "6-20 employees",     from: "Company size"
        check "user_use_company"
        click_button "Update"
      end

      @current_user.reload.name.should eq "Bob Doe"
      @current_user.billing_postal_code.should eq "91470"
      @current_user.billing_country.should eq "FR"
      @current_user.company_name.should eq "Jilion"
      @current_user.company_employees.should eq "6-20 employees"
    end

    scenario "It's possible to update only certain fields" do
      within '#edit_more_info' do
        fill_in "Name",               with: "Bob Doe"
        fill_in "Zip or Postal Code", with: ""
        select  "France",             from: "Country"
        fill_in "Company name",       with: ""
        select  "6-20 employees",     from: "Company size"
        check "user_use_company"
        click_button "Update"
      end

      @current_user.reload.name.should eq "Bob Doe"
      @current_user.billing_postal_code.should eq ""
      @current_user.billing_country.should eq "FR"
      @current_user.company_name.should eq ""
      @current_user.company_employees.should eq "6-20 employees"
    end
  end

end

feature "Billing address update" do

  context "When the user is logged-in" do
    background do
      sign_in_as :user
      go 'my', 'account'

      page.should have_content 'John Doe'
      page.should have_content 'Avenue de France 71'
      page.should have_content 'Batiment B'
      page.should have_content '1004 Lausanne'
      page.should have_content 'SWITZERLAND'

      click_link "Update billing address"

      current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"
    end

    scenario "Update billing address successfully" do
      fill_in "Name",               with: "Bob Doe"
      fill_in "Street 1",           with: "60 rue du hurepoix"
      fill_in "Street 2",           with: ""
      fill_in "Zip or Postal Code", with: "91470"
      fill_in "City",               with: "Limours"
      fill_in "Region",             with: ""
      select  "France",             from: "Country"
      click_button "billing_address_submit"
      go 'my', 'account'

      page.should have_content 'Bob Doe'
      page.should have_content '60 rue du hurepoix'
      page.should have_content '91470 Limours'
      page.should have_content 'FRANCE'
      @current_user.reload.billing_name.should eq "Bob Doe"
    end

    scenario "Update billing address unsuccessfully" do
      fill_in "Name",               with: ""
      fill_in "Street 1",           with: "60 rue du hurepoix"
      fill_in "Street 2",           with: ""
      fill_in "Zip or Postal Code", with: "12345678910"
      fill_in "City",               with: "Limours"
      fill_in "Region",             with: ""
      select  "France",             from: "Country"
      click_button "billing_address_submit"

      page.should have_css '.inline_errors'
      page.should have_content "Postal code is too long (maximum is 10 characters)"
      @current_user.reload.billing_postal_code.should eq "1004"
    end
  end

end

feature "Credit cards update" do

  context "When the user is logged-in and has initially no credit card" do
    background do
      sign_in_as :user, without_cc: true
      @current_user.should_not be_credit_card
      go 'my', 'account'
    end

    scenario "And update is successful" do
      click_link "Register credit card"
      current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"

      set_credit_card type: 'master'
      VCR.use_cassette('ogone/credit_card_visa_validation') { click_button "credit_card_submit" }

      @current_user.reload.cc_type.should eql 'master'
      @current_user.cc_last_digits.should eql '9999'
      should_save_billing_info_successfully 'master'
    end
  end

  context "When the user is logged-in and has initially a credit card on file" do
    background do
      sign_in_as :user
      @current_user.should be_credit_card
      go 'my', 'account'
      should_display_credit_card
      click_link "Update credit card"
      current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"
    end

    scenario "And update is successful" do
      set_credit_card type: 'master'
      VCR.use_cassette('ogone/credit_card_visa_validation') { click_button "credit_card_submit" }

      @current_user.reload.cc_type.should eq 'master'
      @current_user.cc_last_digits.should eq '9999'
      should_save_billing_info_successfully 'master'
    end

    scenario "And update is successful after a successful 3-D Secure identification" do
      set_credit_card type: 'd3d'

      VCR.use_cassette('ogone/3ds_authorization') { click_button "credit_card_submit" }

      @current_user.reload.pending_cc_type.should eq 'visa'
      @current_user.pending_cc_last_digits.should eq '0002'

      page.should have_content "Please click on the \"Continue\" button to continue the processing of your 3-D secure transaction."

      # fake payment succeeded callback (and thus skip the d3d redirection)
      VCR.use_cassette('ogone/void_authorization') { @current_user.process_credit_card_authorization_response("PAYID" => "1234", "STATUS" => "5") }
      @current_user.cc_type.should eq 'visa'
      @current_user.cc_last_digits.should eq '0002'
      @current_user.pending_cc_type.should be_nil
      @current_user.pending_cc_last_digits.should be_nil

      go 'my', '/account'

      should_display_credit_card 'd3d'
      page.should have_no_content I18n.t('flash.billings.update.notice')
    end

    scenario "And update is waiting after a successful 3-D Secure identification" do
      set_credit_card type: 'd3d'
      VCR.use_cassette('ogone/3ds_authorization') { click_button "credit_card_submit" }
      @current_user.reload.pending_cc_type.should eq 'visa'
      @current_user.pending_cc_last_digits.should eq '0002'

      # fake payment waiting callback (and thus skip the d3d redirection)
      VCR.use_cassette('ogone/void_authorization') { @current_user.process_credit_card_authorization_response("PAYID" => "1234", "STATUS" => "51") }
      @current_user.reload.cc_type.should eq 'visa'
      @current_user.cc_last_digits.should eq '1111'
      @current_user.pending_cc_type.should eq 'visa'
      @current_user.pending_cc_last_digits.should eq '0002'

      go 'my', '/account'

      should_display_credit_card
    end

    scenario "And update is unsuccessful after an unsuccessful 3-D Secure identification" do
      set_credit_card type: 'd3d'
      VCR.use_cassette('ogone/3ds_authorization') { click_button "credit_card_submit" }
      @current_user.reload.pending_cc_type.should eq 'visa'
      @current_user.pending_cc_last_digits.should eq '0002'

      # fake payment failed callback (and thus skip the d3d redirection)
      @current_user.process_credit_card_authorization_response("PAYID" => "1234", "STATUS" => "0")

      @current_user.reload.cc_type.should eq 'visa'
      @current_user.cc_last_digits.should eq '1111'
      @current_user.pending_cc_type.should eq 'visa'
      @current_user.pending_cc_last_digits.should eq '0002'

      go 'my', '/account'

      should_display_credit_card
      page.should have_no_content I18n.t('flash.billings.update.notice')
    end

    scenario "And update is unsuccessful with a failed attempt first" do
      fill_in "Card number", with: "123123"
      click_button "credit_card_submit"

      current_url.should eq "http://my.sublimevideo.dev/account/billing"
      page.should have_content "Name on card can't be blank"
      page.should have_content "Card number is invalid"
      page.should have_content "Expiration date expired"
      page.should have_content "CSC is required"

      set_credit_card type: 'master'
      VCR.use_cassette('ogone/credit_card_visa_validation') { click_button "credit_card_submit" }

      should_save_billing_info_successfully 'master'
    end

    scenario "And update does nothing if credit card number is not present" do
      click_button "Update"

      should_save_billing_info_successfully
    end
  end

end

def should_display_credit_card(type = 'visa')
  card_name = case type
  when 'visa', 'd3d'
    'Visa'
  when 'master'
    'MasterCard'
  end
  page.should have_content(card_name)
  page.should have_content(last_digits(type))
end

def should_save_billing_info_successfully(type = 'visa')
  current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"
  should_display_credit_card(type)
  page.should have_content I18n.t('flash.billings.update.notice')
end
