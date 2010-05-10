require File.dirname(__FILE__) + '/acceptance_helper'

feature "Users" do
  
  scenario "Register" do
    visit "/users/register"
    fill_in "Full name", :with => "John Doe"
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Sign up"
    save_and_open_page
  end
  
  scenario "Log in" do
    visit "/users/login"
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Sign in"
    save_and_open_page
  end
  
end