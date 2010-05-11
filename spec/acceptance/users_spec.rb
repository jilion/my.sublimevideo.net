require File.dirname(__FILE__) + '/acceptance_helper'

feature "Users" do
  
  scenario "Signup" do
    visit "/users/register"
    fill_in "Full name", :with => "John Doe"
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Sign up"
    
    current_url.should =~ %r(http://[^/]+/sites)
  end
  
  
  
end