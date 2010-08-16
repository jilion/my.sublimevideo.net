require File.dirname(__FILE__) + '/acceptance_helper'

feature "Credit cards update:" do
  
  background do
    sign_in_as :user, { :without_cc => true }
  end
  
  if MySublimeVideo::Release.public?
    it "add a new credit card" do
      visit "/"
      click_link('Add a Credit Card')
      
      choose 'user_cc_type_visa'
      fill_in 'Name on Card', :with => 'Jime'
      fill_in 'Card number', :with => '4111111111111111'
      select "3", :from => 'user_cc_expire_on_2i'
      select "2011", :from => 'user_cc_expire_on_1i'
      fill_in 'Security Code', :with => '111'
      
      VCR.use_cassette('credit_card_visa_validation') do
        click_button "Update"
      end
      
      current_url.should =~ %r(http://[^/]+/account/edit)
      page.should have_content("Your credit card information was successfully (and securely) saved.")
      page.should have_content('Visa')
      page.should have_content('1111')
    end
  end
  
end