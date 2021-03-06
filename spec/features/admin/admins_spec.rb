require 'spec_helper'

feature "Admin session:" do
  scenario "login" do
    create(:admin, email: "john@doe.com", password: "123456")

    go 'admin', 'login'
    page.should have_no_content 'john@doe.com'
    fill_in "Email",     with: "john@doe.com"
    fill_in "Password",  with: "123456"
    click_button "Log In"

    current_url.should eq "http://admin.sublimevideo.dev/sites"
    page.should have_content 'john@doe.com'
  end

  scenario "logout" do
    sign_in_as :admin, { email: "john@doe.com" }
    page.should have_content 'john@doe.com'
    go 'admin', 'logout'

    current_url.should eq "http://admin.sublimevideo.dev/login"
    page.should_not have_content 'john@doe.com'
  end
end

feature "Admins actions:" do
  background do
    sign_in_as :admin, email: "old@jilion.com"
  end

  scenario "update email" do
    click_link 'old@jilion.com'
    current_url.should eq "http://admin.sublimevideo.dev/account/edit"

    fill_in "Email",            with: "new@jilion.com"
    fill_in "Current password", with: "123456"
    click_button "Update"

    Admin.last.email.should eq "new@jilion.com"
  end

end

feature "Admins invitations:" do
  background do
    ActionMailer::Base.deliveries.clear
    Sidekiq::Worker.clear_all
  end

  scenario "new invitation" do
    sign_in_as :admin, email: "john@doe.com", roles: ['god']

    click_link 'Admins'
    click_link 'Invite an admin'
    current_url.should eq "http://admin.sublimevideo.dev/invitation/new"

    fill_in "Email", with: "invited@admin.com"
    click_button "Send"

    current_url.should eq "http://admin.sublimevideo.dev/admins"
    page.should have_content I18n.translate('devise.invitations.admin.send_instructions')

    Sidekiq::Worker.drain_all

    Admin.last.email.should eq "invited@admin.com"
    Admin.last.invitation_token.should be_present
    ActionMailer::Base.deliveries.should have(1).item

    click_link 'Admins'
    page.should have_content "invited@admin.com"
  end

  scenario "accept invitation" do
    invited_admin = send_invite_to(:admin, "invited@admin.com")
    Sidekiq::Worker.drain_all
    path = %r{https://admin.sublimevideo.dev/(invitation/accept\?invitation_token=\S+)}.match(ActionMailer::Base.deliveries.last.body.encoded)[1]

    go 'admin', path
    current_url.should eq "http://admin.sublimevideo.dev/#{path}"

    fill_in "Password", with: "123456"
    click_button "Go!"

    current_url.should eq "http://admin.sublimevideo.dev/sites"
    invited_admin.email.should eq "invited@admin.com"
    invited_admin.reload.invitation_token.should be_nil
  end

end

feature "Admins pagination:" do
  background do
    sign_in_as :admin, roles: ['god']
    PaginatedResponder.stub(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of admins > Admin.per_page" do
    go 'admin', 'admins'

    page.should have_no_css 'nav.pagination'
    page.should have_no_css 'em.current'
    page.should have_no_selector "a[rel='next']"

    create(:admin)
    go 'admin', 'admins'

    page.should have_css 'nav.pagination'
    page.should have_css 'em.current'
    page.should have_selector "a[rel='next']"
  end
end
