require 'spec_helper'

feature 'Billing address update', :vcr do
  context 'user is not billable' do
    context 'with an incomplete billing address and no credit card' do
      background do
        sign_in_as :user, billing_address_1: '', without_cc: true
        go 'my', 'account/billing/edit'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing/edit'
      end

      scenario 'Updates his billing address and credit card successfully' do
        fields = fill_billing_address
        fill_credit_card
        click_button 'billing_info_submit'
        go 'my', 'account'

        should_display_all_values_from_hash(fields)
      end

      scenario 'Updates his billing address and credit card successfully with a return_to path' do
        go 'my', 'account/billing/edit?return_to=/account/cancel'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing/edit?return_to=%2Faccount%2Fcancel'
        fields = fill_billing_address
        fill_credit_card
        click_button 'billing_info_submit'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/cancel'
      end

      scenario 'Update billing address and credit card unsuccessfully' do
        fill_billing_address(email: 'foo', name: '', zip: '1'*21, region: '')
        fill_credit_card(type: 'master')
        click_button 'billing_info_submit'

        expect(page).to have_css '.inline_errors'
        expect(page).to have_content 'Billing email address is invalid'
        expect(page).to have_content 'Postal code is too long (maximum is 20 characters)'

        go 'my', 'account'
        expect(page).to have_no_content '1'*21
      end
    end

    context 'with an incomplete billing address and a credit card' do
      background do
        sign_in_as :user, billing_address_1: ''
        go 'my', 'account'
        expect(page).to have_no_content 'Your billing address is incomplete.'
        go 'my', 'account/billing/edit'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing/edit'
      end

      UserModules::CreditCard::BRANDS.each do |brand|
        scenario "Updates his billing address and credit card (#{brand}) successfully" do
          fields = fill_billing_address
          fill_credit_card(type: brand)
          click_button 'billing_info_submit'
          go 'my', 'account'

          should_display_all_values_from_hash(fields)
        end

        scenario "Update billing address and credit card (#{brand}) unsuccessfully" do
          fill_billing_address(email: 'foo', name: '', zip: '1'*21, region: '')
          fill_credit_card(type: brand)
          click_button 'billing_info_submit'

          expect(page).to have_css '.inline_errors'
          expect(page).to have_content 'Postal code is too long (maximum is 20 characters)'

          go 'my', 'account'
          expect(page).to have_no_content '1'*21
        end
      end
    end
  end

  context 'user is billable' do
    context 'with an incomplete billing address and a missing billing email' do
      background do
        sign_in_as :user_with_site
        create(:billable_item, site: @current_user.sites.first, item: create(:addon_plan), state: 'subscribed')
        expect(@current_user).to be_billable
        @current_user.update(billing_address_1: '', billing_email: '')
        go 'my', 'account'
        expect(page).to have_content 'Your billing address is incomplete.'
        expect(page).to have_content 'No billing email address specified.'
        click_link 'Update billing address'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing/edit'
      end

      scenario 'Update billing address successfully' do
        fields = fill_and_submit_billing_address
        go 'my', 'account'

        should_display_all_values_from_hash(fields)
      end

      scenario 'Update billing address unsuccessfully' do
        fill_and_submit_billing_address(email: 'foo', name: '', zip: '1'*21, region: '')

        expect(page).to have_css '.inline_errors'
        expect(page).to have_content 'Postal code is too long (maximum is 20 characters)'

        go 'my', 'account'
        expect(page).to have_no_content '1'*21
      end
    end
  end
end

feature 'Credit cards update', :vcr do
  context 'user is logged-in and has initially no credit card' do
    background do
      sign_in_as :user, without_cc: true
      go 'my', 'account'
      expect(page).to have_content 'No credit card on file.'
    end

    UserModules::CreditCard::BRANDS.each do |brand|
      scenario "And update is successful (#{brand})" do
        click_link 'Register credit card'
        expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing/edit'

        fill_credit_card(type: brand)
        click_button 'credit_card_submit'

        expect(@current_user.reload.cc_type).to eql brand
        expect(@current_user.cc_last_digits).to eql send("valid_cc_attributes_#{brand}")[:cc_number][-4,4]
        should_save_billing_info_successfully(brand)
      end
    end
  end

  context 'user is logged-in and has initially a credit card on file' do
    background do
      sign_in_as :user
      go 'my', 'account'
      should_display_credit_card
      click_link 'Update credit card'
      expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing/edit'
    end

    scenario 'update is successful' do
      fill_credit_card
      click_button 'credit_card_submit'

      should_save_billing_info_successfully
    end

    scenario 'update is successful after a successful 3-D Secure identification', :vcr do
      fill_credit_card(type: 'd3d')

      click_button 'credit_card_submit'

      expect(@current_user.reload.pending_cc_type).to eq 'visa'
      expect(@current_user.pending_cc_last_digits).to eq '0002'

      expect(page).to have_content 'Please click on the "Continue" button to continue the processing of your 3-D secure transaction.'

      # fake payment succeeded callback (and thus skip the d3d redirection)
      @current_user.process_credit_card_authorization_response('BRAND' => 'American Express', 'PAYID' => '1234', 'STATUS' => '5')
      expect(@current_user.cc_type).to eq 'visa'
      expect(@current_user.cc_last_digits).to eq '0002'
      expect(@current_user.pending_cc_type).to be_nil
      expect(@current_user.pending_cc_last_digits).to be_nil

      go 'my', '/account'

      should_display_credit_card 'd3d'
      expect(page).to have_no_content I18n.t('flash.billings.update.notice')
    end

    scenario 'update is waiting after a successful 3-D Secure identification', :vcr do
      fill_credit_card(type: 'd3d')
      click_button 'credit_card_submit'
      expect(@current_user.reload.pending_cc_type).to eq 'visa'
      expect(@current_user.pending_cc_last_digits).to eq '0002'

      # fake payment waiting callback (and thus skip the d3d redirection)
      @current_user.process_credit_card_authorization_response('BRAND' => 'American Express', 'PAYID' => '1234', 'STATUS' => '51')
      expect(@current_user.reload.cc_type).to eq 'visa'
      expect(@current_user.cc_last_digits).to eq '1111'
      expect(@current_user.pending_cc_type).to eq 'visa'
      expect(@current_user.pending_cc_last_digits).to eq '0002'

      go 'my', '/account'

      should_display_credit_card
    end

    scenario 'update is unsuccessful after an unsuccessful 3-D Secure identification' do
      fill_credit_card type: 'd3d'
      click_button 'credit_card_submit'
      expect(@current_user.reload.pending_cc_type).to eq 'visa'
      expect(@current_user.pending_cc_last_digits).to eq '0002'

      # fake payment failed callback (and thus skip the d3d redirection)
      @current_user.process_credit_card_authorization_response('BRAND' => 'American Express', 'PAYID' => '1234', 'STATUS' => '0')

      expect(@current_user.reload.cc_type).to eq 'visa'
      expect(@current_user.cc_last_digits).to eq '1111'
      expect(@current_user.pending_cc_type).to eq 'visa'
      expect(@current_user.pending_cc_last_digits).to eq '0002'

      go 'my', '/account'

      should_display_credit_card
      expect(page).to have_no_content I18n.t('flash.billings.update.notice')
    end

    scenario 'update is successful with a failed attempt first' do
      fill_in 'Card number', with: '123123'
      click_button 'credit_card_submit'

      expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing'
      expect(page).to have_content "Name on card can't be blank"
      expect(page).to have_content 'Card number is invalid'
      expect(page).to have_content 'CSC is required'

      fill_credit_card
      click_button 'credit_card_submit'

      should_save_billing_info_successfully
    end

    scenario 'update is successful with a failed attempt first with a return_to path' do
      go 'my', 'account/billing/edit?return_to=/account/cancel'
      expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing/edit?return_to=%2Faccount%2Fcancel'
      fill_in 'Card number', with: '123123'
      click_button 'credit_card_submit'

      expect(current_url).to eq 'http://my.sublimevideo.dev/account/billing'
      expect(page).to have_content "Name on card can't be blank"
      expect(page).to have_content 'Card number is invalid'
      expect(page).to have_content 'CSC is required'

      fill_credit_card
      click_button 'credit_card_submit'
      expect(current_url).to eq 'http://my.sublimevideo.dev/account/cancel'
    end

    scenario 'update does nothing if credit card number is not present' do
      click_button 'credit_card_submit'

      should_save_billing_info_successfully
    end
  end

end

def should_display_all_values_from_hash(hash)
  hash.each do |k, v|
    expect(page).to have_content v
  end
end

def should_display_credit_card(type = 'visa')
  expect(page).to have_content(I18n.t("user.credit_card.type.#{type == 'd3d' ? 'visa' : type}"))
  expect(page).to have_content(last_digits(type))
end

def should_save_billing_info_successfully(type = 'visa')
  expect(current_url).to eq "http://my.sublimevideo.dev/account"
  should_display_credit_card(type)
  expect(page).to have_content I18n.t('flash.billings.update.notice')
end
