require 'spec_helper'

feature "Admin session:" do
  scenario "login" do
    create(:admin, email: "john@doe.com", password: "123456")

    go 'admin', 'login'
    expect(page).to have_no_content 'john@doe.com'
    fill_in "Email",     with: "john@doe.com"
    fill_in "Password",  with: "123456"
    click_button "Log In"

    expect(current_url).to eq "http://admin.sublimevideo.dev/sites"
    expect(page).to have_content 'john@doe.com'
  end

  scenario "logout" do
    sign_in_as :admin, { email: "john@doe.com" }
    expect(page).to have_content 'john@doe.com'
    go 'admin', 'logout'

    expect(current_url).to eq "http://admin.sublimevideo.dev/login"
    expect(page).not_to have_content 'john@doe.com'
  end
end

feature "Token authentication:" do
  scenario "works" do
    create(:admin, email: "john@doe.com", password: "123456")
    admin = Admin.last
    admin.reset_authentication_token!
    go 'admin', "app/components.json?auth_token=#{admin.authentication_token}"
    expect(page.driver.status_code).to eq 200
  end

  scenario "fails" do
    go 'admin', 'app/components.json?auth_token=FAIL'
    expect(page.driver.status_code).to eq 401
    expect(page.body).to include('Invalid authentication token.')
  end
end

feature "Admins actions:" do
  background do
    sign_in_as :admin, email: "old@jilion.com"
  end

  scenario "update email" do
    click_link 'old@jilion.com'
    expect(current_url).to eq "http://admin.sublimevideo.dev/account/edit"

    fill_in "Email",            with: "new@jilion.com"
    fill_in "Current password", with: "123456"
    click_button "Update"

    expect(Admin.last.email).to eq "new@jilion.com"
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
    expect(current_url).to eq "http://admin.sublimevideo.dev/invitation/new"

    fill_in "Email", with: "invited@admin.com"
    click_button "Send"

    expect(current_url).to eq "http://admin.sublimevideo.dev/admins"
    expect(page).to have_content I18n.translate('devise.invitations.admin.send_instructions')

    Sidekiq::Worker.drain_all

    expect(Admin.last.email).to eq "invited@admin.com"
    expect(Admin.last.invitation_token).to be_present
    expect(ActionMailer::Base.deliveries.size).to eq(1)

    click_link 'Admins'
    expect(page).to have_content "invited@admin.com"
  end

  scenario "accept invitation" do
    invited_admin = send_invite_to(:admin, "invited@admin.com")

    go 'admin', "invitation/accept?invitation_token=#{invited_admin.invitation_token}"
    expect(current_url).to eq "http://admin.sublimevideo.dev/invitation/accept\?invitation_token=#{invited_admin.invitation_token}"
    fill_in "Password", with: "123456"
    click_button "Go!"

    expect(current_url).to eq "http://admin.sublimevideo.dev/sites"
    expect(invited_admin.email).to eq "invited@admin.com"
    expect(invited_admin.reload.invitation_token).to be_nil
  end

end

feature "Admins pagination:" do
  background do
    sign_in_as :admin, roles: ['god']
    allow(PaginatedResponder).to receive(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of admins > Admin.per_page" do
    go 'admin', 'admins'

    expect(page).to have_no_css 'nav.pagination'
    expect(page).to have_no_css 'em.current'
    expect(page).to have_no_selector "a[rel='next']"

    create(:admin)
    go 'admin', 'admins'

    expect(page).to have_css 'nav.pagination'
    expect(page).to have_css 'em.current'
    expect(page).to have_selector "a[rel='next']"
  end
end
