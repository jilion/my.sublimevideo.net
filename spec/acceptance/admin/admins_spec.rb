require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Admin session:" do
  
  scenario "login" do
    create_admin :admin => { :email => "john@doe.com", :password => "123456" }
    
    visit "/admin/login"
    current_url.should =~ %r(http://[^/]+/admin/admins/login)
    page.should_not have_content 'john@doe.com'
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Login"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles)
    page.should have_content 'john@doe.com'
  end
  
  scenario "logout" do
    sign_in_as :admin, { :email => "john@doe.com" }
    page.should have_content 'john@doe.com'
    click_link "Logout"
    
    current_url.should =~ %r(http://[^/]+/admin/admins/login)
    page.should_not have_content 'john@doe.com'
  end
  
end

feature "Admins actions:" do
  background do
    sign_in_as :admin, { :email => "old@jilion.com" }
  end
    
  scenario "update email" do
    click_link 'old@jilion.com'
    current_url.should =~ %r(http://[^/]+/admin/admins/edit)
    
    fill_in "Email",            :with => "new@jilion.com"
    fill_in "Current password", :with => "123456"
    click_button "admin_submit"
    
    Admin.last.email.should == "new@jilion.com"
  end
  
end

feature "Admins invitations:" do
  background do
    ActionMailer::Base.deliveries = []
  end
  
  scenario "new invitation" do
    sign_in_as :admin, { :email => "john@doe.com" }
    
    click_link 'Admins'
    current_url.should =~ %r(http://[^/]+/admin/admins)
    
    click_link 'Invite an admin'
    current_url.should =~ %r(http://[^/]+/admin/admins/invitation/new)
    
    fill_in "Email", :with => "invited@admin.com"
    click_button "Send"
    
    current_url.should =~ %r(http://[^/]+/admin/admins)
    page.should have_content(I18n.translate('devise.invitations.admin.send_instructions'))
    
    Admin.last.email.should == "invited@admin.com"
    Admin.last.invitation_token.should be_present
    ActionMailer::Base.deliveries.size.should == 1
    
    click_link 'Admins'
    page.should have_content "invited@admin.com"
  end
  
  scenario "accept invitation" do
    sign_in_as :admin, { :email => "john@doe.com" }
    visit '/admin/admins/invitation/new'
    fill_in "Email", :with => "invited@admin.com"
    click_button "Send"
    
    page.should have_content(I18n.translate('devise.invitations.admin.send_instructions'))
    Admin.last.email.should == "invited@admin.com"
    Admin.last.invitation_token.should be_present
    
    sign_out
    
    visit "/admin/admins/invitation/edit?invitation_token=#{Admin.last.invitation_token}"
    current_url.should =~ %r(http://[^/]+/admin/admins/invitation/edit\?invitation_token=#{Admin.last.invitation_token})
    fill_in "Password", :with => "123456"
    click_button "Go!"
    
    current_url.should =~ %r(http://[^/]+/admin/admins)
    page.should have_content(I18n.translate('devise.invitations.admin.updated'))
    
    Admin.last.email.should == "invited@admin.com"
    Admin.last.invitation_token.should be_nil
    
    click_link 'Admins'
    page.should have_content "invited@admin.com"
  end
  
end