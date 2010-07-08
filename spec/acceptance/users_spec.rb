require File.dirname(__FILE__) + '/acceptance_helper'

feature "Users actions:" do
  
  # scenario "register is available after the beta!" do
  scenario "register is not available during the beta!" do # BETA 
    visit "/register"                                      # BETA 
    current_url.should =~ %r(http://[^/]+/login)           # BETA 
    
    # fill_in "Full name", :with => "John Doe"
    # fill_in "Email",     :with => "john@doe.com"
    # fill_in "Password",  :with => "123456"
    # check "I agree to the Terms & Conditions."
    # click_button "Register"
    # 
    # current_url.should =~ %r(http://[^/]+/sites)
    # page.should have_content('John Doe')
  end
  
  scenario "update email" do
    sign_in_as_user :user => { :email => "old@jilion.com", :full_name => "John Doe" }
    click_link('John Doe')
    fill_in "Email",            :with => "new@jilion.com"
    fill_in "Current password", :with => "123456"
    click_button "user_submit"
    
    User.last.email.should == "new@jilion.com"
  end
  
  scenario "update full name" do
    sign_in_as_user :user => { :full_name => "John Doe" }
    click_link('John Doe')
    fill_in "Full name",  :with => "Bob Doe"
    click_button "user_full_name_submit"
    
    page.should have_content('Bob Doe')
    User.last.full_name.should == "Bob Doe"
  end
  
  scenario "update limit alert amount" do
    sign_in_as_user :user => { :full_name => "John Doe" }
    click_link('John Doe')
    select "$100", :from => "user_limit_alert_amount"
    click_button "user_email_notifications_submit"
    
    User.last.limit_alert_amount.should == 10000
  end
  
  scenario "update video settings" do
    sign_in_as_user :user => { :full_name => "John Doe" }
    click_link('John Doe')
    # check "user_video_settings_webm"
    fill_in "user_video_settings_default_video_embed_width", :with => 200
    click_button "user_video_settings_submit"
    
    # User.last.should be_use_webm
    User.last.default_video_embed_width.should == 200
  end
  
end

feature "User session:" do
  
  scenario "login" do
    create_user  :user => { :full_name => "John Doe", :email => "john@doe.com", :password => "123456" }
    
    visit "/login"
    page.should_not have_content('John Doe')
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Login"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content('John Doe')
  end
  
  scenario "logout" do
    sign_in_as_user :user => { :full_name => "John Doe" }
    page.should have_content('John Doe')
    click_link "Logout"
    
    current_url.should =~ %r(http://[^/]+/login)
    page.should_not have_content('John Doe')
  end
  
end

feature "User confirmation:" do
  
  scenario "confirmation" do
    create_user  :user => { :full_name => "John Doe", :email => "john@doe.com", :password => "123456" }, :confirm => false
    
    visit "/users/confirmation?confirmation_token=#{@current_user.confirmation_token}"
    
    page.should have_content(I18n.translate('devise.confirmations.confirmed'))
  end
  
end