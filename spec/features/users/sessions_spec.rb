require 'spec_helper'

feature 'Session management' do
  let(:user) { create(:user) }

  scenario "login" do
    go 'my', '/gs-login'

    fill_in 'user[email]',    with: user.email
    fill_in 'user[password]', with: "123456"

    click_button "Log In"

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
  end

  scenario "logout" do
    sign_in_as :user, { name: "John Doe" }
    page.should have_content "John Doe"
    click_link "logout"

    # Not working with external url
    # current_url.should eq "http://sublimevideo.dev/"
    page.should_not have_content "John Doe"
  end
end
