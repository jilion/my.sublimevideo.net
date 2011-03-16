require 'spec_helper'

feature "Credit cards update:" do

  context "user has no credit card" do
    background do
      sign_in_as :user, :without_cc => true
      @current_user.should_not be_credit_card
    end

    scenario "edit a new credit card" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account/edit$)

      page.should_not have_content("Add a credit card")

      visit "/card/edit"

      current_url.should =~ %r(^http://[^/]+/account/edit$)
    end

  end

  context "user already has a credit card" do
    background do
      sign_in_as :user
      @current_user.should be_credit_card
    end

    scenario "edit a new credit card" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account/edit$)

      click_link("Update credit card")
      current_url.should =~ %r(^http://[^/]+/card/edit$)

      set_credit_card
      should_save_credit_card_successfully
    end

    scenario "edit a new credit card with a failed attempt" do
      click_link(@current_user.full_name)
      current_url.should =~ %r(^http://[^/]+/account/edit$)

      click_link("Update credit card")
      current_url.should =~ %r(^http://[^/]+/card/edit$)

      set_credit_card(false)

      current_url.should =~ %r(^http://[^/]+/card$)
      page.should have_content("Name on card can't be blank")
      page.should have_content("Card number is invalid")
      page.should have_content("CSC is required")

      set_credit_card
      should_save_credit_card_successfully
    end
  end
end

def set_credit_card(valid=true)
  if valid
    choose 'user_cc_type_visa'
    fill_in 'Name on card', :with => 'Jime'
    fill_in 'Card number', :with => '4111111111111111'
    select "3", :from => 'user_cc_expire_on_2i'
    select "2011", :from => 'user_cc_expire_on_1i'
    fill_in 'Security Code', :with => '111'
  end
  VCR.use_cassette('ogone/credit_card_visa_validation') do
    click_button "Update"
  end
end

def should_save_credit_card_successfully
  current_url.should =~ %r(^http://[^/]+/account/edit$)
  page.should have_content("Your credit card information was successfully (and securely) saved.")
  page.should have_content('Visa')
  page.should have_content('1111')
end