# coding: utf-8
require 'spec_helper'

feature "Users actions:" do
  
  pending "register is available after the public release" do
    visit "/register"
    current_url.should =~ %r(http://[^/]+/register)
    
    fill_in "Full name", :with => "John Doe"
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    check "I agree to the Terms & Conditions."
    click_button "Register"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content "John Doe"
  end
  
  scenario "update email" do
    sign_in_as :user, { :email => "old@jilion.com" }
    click_link('John Doe')
    fill_in "Email",            :with => "New@jilion.com"
    fill_in "Current password", :with => "123456"
    click_button "user_credentials_submit"
    
    User.last.email.should == "new@jilion.com"
  end
  
  scenario "update password" do
    sign_in_as :user
    click_link('John Doe')
    fill_in "Password", :with => "newpassword"
    fill_in "Current password", :with => "123456"
    click_button "user_credentials_submit"
    
    User.last.valid_password?("newpassword").should be_true
  end
  
  scenario "update first name" do
    sign_in_as :user
    click_link('John Doe')
    fill_in "First name",  :with => "Bob"
    click_button "user_submit"
    
    page.should have_content('Bob Doe')
    User.last.full_name.should == "Bob Doe"
  end
  
  scenario "update first name with errors" do
    sign_in_as :user
    click_link('John Doe')
    fill_in "First name",  :with => ""
    click_button "user_submit"
    
    page.should have_css('.inline_errors')
    page.should have_content("First name can't be blank")
    User.last.full_name.should == "John Doe"
  end
  
  scenario "accept invitation without token should redirect to /login" do
    visit "/invitation/accept"
    current_url.should =~ %r(^http://[^/]+/login$)
  end
  
  scenario "accept invitation with invalid token should redirect to /login" do
    visit "/invitation/accept?invitation_token=foo"
    current_url.should =~ %r(^http://[^/]+/login$)
  end
  
  scenario "accept invitation" do
    invited_user = send_invite_to :user, "invited@user.com"
    
    visit "/invitation/accept?invitation_token=#{invited_user.invitation_token}"
    current_url.should =~ %r(http://[^/]+/invitation/accept\?invitation_token=#{invited_user.invitation_token})
    
    fill_in "Password", :with => "123456"
    fill_in "First name", :with => "Rémy"
    fill_in "Last name", :with => "Coutable"
    select "Switzerland", :from => "Country"
    fill_in "Zip or Postal Code", :with => "CH-1024"
    check "Personal"
    check "user_terms_and_conditions"
    click_button "Join"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content "Rémy Coutable"
    
    invited_user.reload.full_name.should == "Rémy Coutable"
    invited_user.email.should == "invited@user.com"
    invited_user.invitation_token.should be_nil
  end
  
  scenario "accept invitation with company info" do
    invited_user = send_invite_to :user, "invited@user.com"
    
    visit "/invitation/accept?invitation_token=#{invited_user.invitation_token}"
    
    fill_in "Password", :with => "123456"
    fill_in "First name", :with => "Rémy"
    fill_in "Last name", :with => "Coutable"
    select "Switzerland", :from => "Country"
    fill_in "Zip or Postal Code", :with => "CH-1024"
    
    check "For my company"
    fill_in "Company name", :with => "Jilion"
    fill_in "Company website", :with => "jilion.com"
    fill_in "Job title", :with => "Dev"
    select "2-5 employees", :from => "Company size"
    select "1'000-10'000 videos/month", :from => "Nr. of videos served"
    
    check "user_terms_and_conditions"
    click_button "Join"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content "Rémy Coutable"
  end
  
  scenario "accept invitation and change email" do
    invited_user = send_invite_to :user, "invited@user.com"
    
    visit "/invitation/accept?invitation_token=#{invited_user.invitation_token}"
    
    fill_in "Password", :with => "123456"
    fill_in "Email", :with => "new@email.com"
    fill_in "First name", :with => "Rémy"
    fill_in "Last name", :with => "Coutable"
    select "Switzerland", :from => "Country"
    fill_in "Zip or Postal Code", :with => "CH-1024"
    check "Personal"
    check "user_terms_and_conditions"
    click_button "Join"
    
    invited_user.reload.email.should == "new@email.com"
  end
  
  feature "with an authenticated user" do
    background do
      sign_in_as :user
    end
    
    scenario "accept invitation without token should redirect to /sites" do
      visit "/invitation/accept"
      current_url.should =~ %r(^http://[^/]+/sites$)
    end
    
    scenario "accept invitation with invalid token should redirect to /sites" do
      visit "/invitation/accept?invitation_token=foo"
      current_url.should =~ %r(^http://[^/]+/sites$)
    end
    
    scenario "accept invitation with valid token should redirect to /sites" do
      invited_user = send_invite_to :user, "invited@user.com"
      
      visit "/invitation/accept?invitation_token=#{invited_user.invitation_token}"
      current_url.should =~ %r(^http://[^/]+/sites$)
    end
  end
  
end

feature "User session:" do
  
  scenario "before login/register" do
    visit "/"
    
    page.should_not have_content('Feedback')
    page.should_not have_content('Logout')
    
    page.should have_content('Login')
    page.should have_content('Documentation')
  end
  
  scenario "login" do
    create_user :user => {
      :first_name => "John",
      :last_name => "Doe",
      :email => "john@doe.com",
      :password => "123456"
    }
    
    visit "/login"
    page.should_not have_content('John Doe')
    fill_in "Email",     :with => "John@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Login"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content "John Doe"
  end
  
  scenario "logout" do
    sign_in_as :user, { :first_name => "John", :last_name => "Doe" }
    page.should have_content "John Doe"
    click_link "Logout"
    
    current_url.should =~ %r(http://[^/]+/login)
    page.should_not have_content "John Doe"
  end
  
end

feature "User confirmation:" do
  
  scenario "confirmation" do
    user = create_user :user => { :first_name => "John", :last_name => "Doe", :email => "john@doe.com", :password => "123456" }, :confirm => false
    
    visit "/confirmation?confirmation_token=#{user.confirmation_token}"
    
    page.should have_content(I18n.translate('devise.confirmations.confirmed'))
  end
  
end