require 'spec_helper'

feature "Admin session:" do

  scenario "login" do
    create_admin :admin => { :email => "john@doe.com", :password => "123456" }

    visit "/admin/login"
    current_url.should =~ %r(http://[^/]+/admin/login)
    page.should_not have_content 'john@doe.com'
    fill_in "Email",     :with => "john@doe.com"
    fill_in "Password",  :with => "123456"
    click_button "Login"

    current_url.should =~ %r(http://[^/]+/admin/djs)
    page.should have_content 'john@doe.com'
  end

  scenario "logout" do
    sign_in_as :admin, { :email => "john@doe.com" }
    page.should have_content 'john@doe.com'
    click_link "Logout"

    current_url.should =~ %r(http://[^/]+/admin/login)
    page.should_not have_content 'john@doe.com'
  end

end

feature "Admins actions:" do
  background do
    sign_in_as :admin, { :email => "old@jilion.com" }
  end

  scenario "update email" do
    click_link 'old@jilion.com'
    current_url.should =~ %r(http://[^/]+/admin/account/edit)

    fill_in "Email",            :with => "new@jilion.com"
    fill_in "Current password", :with => "123456"
    click_button "admin_submit"

    Admin.last.email.should == "new@jilion.com"
  end

end

feature "Admins invitations:" do
  background do
    ActionMailer::Base.deliveries.clear
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
    invited_admin = send_invite_to :admin, "invited@admin.com"

    visit "/admin/invitation/accept?invitation_token=#{invited_admin.invitation_token}"
    current_url.should =~ %r(http://[^/]+/admin/invitation/accept\?invitation_token=#{invited_admin.invitation_token})
    fill_in "Password", :with => "123456"
    click_button "Go!"

    current_url.should =~ %r(http://[^/]+/admin/djs)
    page.should have_content(I18n.translate('devise.invitations.admin.updated'))
    invited_admin.email.should == "invited@admin.com"
    invited_admin.reload.invitation_token.should be_nil

    click_link 'Admins'
    page.should have_content "invited@admin.com"
  end

end

feature "Admins pagination:" do
  background do
    sign_in_as :admin
    Responders::PaginatedResponder.stub(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of amins > Admin.per_page" do
    Admin.all.size.should == 1

    visit "/admin/admins"
    page.should have_no_css('nav.pagination')
    page.should have_no_css('span.prev')
    page.should have_no_css('em.current')
    page.should have_no_css('a.next')

    FactoryGirl.create(:admin)
    visit "/admin/admins"

    page.should have_css('nav.pagination')
    page.should have_css('span.prev')
    page.should have_css('em.current')
    page.should have_css('a.next')
  end
end