require 'spec_helper'

feature 'Log in' do
  let(:user) { create(:user, email: 'john@doe.com') }

  context 'active user' do
    scenario "is able log in" do
      go 'my', '/login'

      fill_in 'user[email]',    with: user.email
      fill_in 'user[password]', with: "123456"

      click_button "Log In"

      current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    end

    scenario "is able log in using the Get Satisfaction login route" do
      go 'my', '/gs-login'

      fill_in 'user[email]',    with: user.email
      fill_in 'user[password]', with: "123456"

      click_button "Log In"

      current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    end
  end

  context 'with an existing archived user with the same email' do
    scenario "the active user is able log in" do
      archived_user = create(:user, email: 'john@doe.com', password: '123456')
      archived_user.current_password = '123456'
      archived_user.archive

      go 'my', '/login'

      fill_in 'user[email]',    with: user.email
      fill_in 'user[password]', with: "123456"

      click_button "Log In"

      current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    end
  end
end

feature 'Log out' do
  scenario "the logged-in user is able log out" do
    sign_in_as :user, { name: "John Doe" }
    page.should have_content "John Doe"
    click_link "logout"

    page.should_not have_content "John Doe"
  end
end
