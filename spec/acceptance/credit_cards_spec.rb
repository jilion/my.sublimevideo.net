require File.dirname(__FILE__) + '/acceptance_helper'

feature "Credit cards update:" do
  
  background do
    sign_in_as_user
  end
  
  pending "add a new video" do
    visit "/"
    click_link('Add a Credit Card')
    
    choose 'visa'
    fill_in 'Credit card number', :with => '4111111111111111'
    select "3", :from => 'user_cc_expire_on_2i'
    select "2011", :from => 'user_cc_expire_on_1i'
    fill_in 'user[cc_full_name]', :with => 'John Doe'
    fill_in 'Verification value', :with => '111'
    
    VCR.use_cassette('credit_card_visa_validation') do
      click_button "Update"
    end
    
    current_url.should =~ %r(http://[^/]+/users/edit)
    page.should have_content('Visa')
    page.should have_content('1111')
  end
  
end