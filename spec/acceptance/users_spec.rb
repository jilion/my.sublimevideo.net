require File.dirname(__FILE__) + '/acceptance_helper'

feature "Users actions:" do
  
  if MySublimeVideo::Release.public?
    scenario "register is available after the public release" do
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
  else
    scenario "register is not available before the public release" do
      visit "/register"
      current_url.should =~ %r(http://[^/]+/login)
    end
  end
  
  scenario "update email" do
    sign_in_as :user, { :email => "old@jilion.com", :full_name => "John Doe" }
    click_link('John Doe')
    fill_in "Email",            :with => "new@jilion.com"
    fill_in "Current password", :with => "123456"
    click_button "user_submit"
    
    User.last.email.should == "new@jilion.com"
  end
  
  scenario "update full name" do
    sign_in_as :user, { :full_name => "John Doe" }
    click_link('John Doe')
    fill_in "Full name",  :with => "Bob Doe"
    click_button "user_full_name_submit"
    
    page.should have_content('Bob Doe')
    User.last.full_name.should == "Bob Doe"
  end
  
  scenario "update full name with errors" do
    sign_in_as :user, { :full_name => "John Doe" }
    click_link('John Doe')
    fill_in "Full name",  :with => ""
    click_button "user_full_name_submit"
    
    page.should have_css('.inline_errors')
    page.should have_content("Full name can't be blank")
    User.last.full_name.should == "John Doe"
  end
  
  if MySublimeVideo::Release.public?
    scenario "update limit alert amount" do
      sign_in_as :user, { :full_name => "John Doe" }
      click_link('John Doe')
      select "$100", :from => "user_limit_alert_amount"
      click_button "user_email_notifications_submit"
      
      User.last.limit_alert_amount.should == 10000
    end
  end
  
  scenario "accept invitation" do
    invited_user = send_invite_to :user, "invited@user.com"
    
    visit "/invitation/accept?invitation_token=#{invited_user.invitation_token}"
    current_url.should =~ %r(http://[^/]+/invitation/accept\?invitation_token=#{invited_user.invitation_token})
    fill_in "Full name", :with => "Rémy Coutable"
    fill_in "Password", :with => "123456"
    click_button "Join"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content "Welcome" if MySublimeVideo::Release.public?
    page.should have_content "Rémy Coutable"
    
    invited_user.reload.full_name.should == "Rémy Coutable"
    invited_user.email.should == "invited@user.com"
    invited_user.invitation_token.should be_nil
  end
  
  scenario "accept invitation and change email" do
    invited_user = send_invite_to :user, "invited@user.com"
    
    visit "/invitation/accept?invitation_token=#{invited_user.invitation_token}"
    fill_in "Email", :with => "new@email.com"
    fill_in "Full name", :with => "Rémy Coutable"
    fill_in "Password", :with => "123456"
    click_button "Join"
    
    invited_user.reload.email.should == "new@email.com"
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
    create_user :user => { :full_name => "John Doe", :email => "john@doe.com", :password => "123456" }
    
    visit "/login"
    page.should_not have_content('John Doe')
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Login"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content "John Doe"
  end
  
  scenario "logout" do
    sign_in_as :user, { :full_name => "John Doe" }
    page.should have_content "John Doe"
    click_link "Logout"
    
    current_url.should =~ %r(http://[^/]+/login)
    page.should_not have_content "John Doe"
  end
  
end

feature "User confirmation:" do
  
  scenario "confirmation" do
    user = create_user :user => { :full_name => "John Doe", :email => "john@doe.com", :password => "123456" }, :confirm => false
    
    visit "/confirmation?confirmation_token=#{user.confirmation_token}"
    
    page.should have_content(I18n.translate('devise.confirmations.confirmed'))
  end
  
end