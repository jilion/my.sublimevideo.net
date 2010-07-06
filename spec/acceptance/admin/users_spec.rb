require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Users invitations:" do
  background do
    ActionMailer::Base.deliveries.clear
  end
  
  scenario "new invitation" do
    sign_in_as :admin, { :email => "john@doe.com" }
    
    click_link 'Users'
    current_url.should =~ %r(http://[^/]+/admin/users)
    
    click_link 'Invite a user'
    current_url.should =~ %r(http://[^/]+/users/invitation/new)
    
    fill_in "Email", :with => "invited@user.com"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/admin/users)
    page.should have_content(I18n.translate('devise.invitations.user.send_instructions'))
    
    User.last.email.should == "invited@user.com"
    User.last.invitation_token.should be_present
    ActionMailer::Base.deliveries.size.should == 1
    
    click_link 'Users'
    page.should have_content "invited@user.com"
  end
  
  scenario "accept invitation" do
    sign_in_as :admin, { :email => "john@doe.com" }
    visit '/users/invitation/new'
    fill_in "Email", :with => "invited@user.com"
    click_button "Send"
    
    page.should have_content(I18n.translate('devise.invitations.user.send_instructions'))
    User.last.email.should == "invited@user.com"
    User.last.invitation_token.should be_present
    
    sign_out
    
    visit "/users/invitation/edit?invitation_token=#{User.last.invitation_token}"
    current_url.should =~ %r(http://[^/]+/users/invitation/edit\?invitation_token=#{User.last.invitation_token})
    fill_in "Full name", :with => "Rémy Coutable"
    fill_in "Password", :with => "123456"
    click_button "Go!"
    
    current_url.should =~ %r(http://[^/]+/sites)
    page.should have_content("Welcome")
    page.should have_content "Rémy Coutable"
    
    User.last.full_name.should == "Rémy Coutable"
    User.last.email.should == "invited@user.com"
    User.last.invitation_token.should be_nil
  end
  
end