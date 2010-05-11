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
  
  scenario "Email update" do
    sign_in_as_user :email => "old@jilion.com", :full_name => "John Doe"
    click_link('John Doe')
    fill_in "Email",            :with => "new@jilion.com"
    fill_in "Current password", :with => "123456"
    click_button "user_submit"
    
    User.last.email.should == "new@jilion.com"
  end
  
  scenario "Full name update" do
    sign_in_as_user :full_name => "John Doe"
    click_link('John Doe')
    fill_in "Full name",  :with => "Bob Doe"
    click_button "user_email_submit"
    
    page.should have_content('Bob Doe')
    User.last.full_name.should == "Bob Doe"
  end
  
end