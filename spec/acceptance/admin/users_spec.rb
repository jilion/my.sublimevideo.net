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
    current_url.should =~ %r(http://[^/]+/admin/users/invitation/new)
    
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
  
end

feature "Users pagination:" do
  background do
    sign_in_as :admin
    User.stub!(:per_page).and_return(1)
  end
  
  scenario "pagination links displayed only if count of users > User.per_page" do
    Factory(:user)
    Admin.all.size.should == 1
    visit "/admin/users"
    page.should have_no_css('div.pagination')
    page.should have_no_css('span.previous_page')
    page.should have_no_css('em.current_page')
    page.should have_no_css('a.next_page')
    
    Factory(:user)
    visit "/admin/users"
    
    page.should have_css('div.pagination')
    page.should have_css('span.previous_page')
    page.should have_css('em.current_page')
    page.should have_css('a.next_page')
  end
end