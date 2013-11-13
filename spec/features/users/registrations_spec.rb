require 'spec_helper'

feature 'Sign Up' do
  background do
    go 'my', '/signup'
    expect(current_url).to eq "http://my.sublimevideo.dev/signup"
  end

  scenario 'display errors if any' do
    fill_in 'user[email]',    with: 'user@example.org'
    fill_in 'user[password]', with: "123456"
    click_button "Sign Up"

    expect(current_url).to eq "http://my.sublimevideo.dev/signup"
    expect(page).to have_content 'Terms & Conditions must be accepted'

    fill_in "Password", with: "123456"
    check "user_terms_and_conditions"
    click_button "Sign Up"

    user = User.last
    expect(user.name).to be_nil
    expect(user.email).to eq 'user@example.org'

    expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
    expect(get_me_the_cookie("l")[:value]).to eq '1'
    expect(page).to have_content I18n.t("devise.users.signed_up")
    expect(page).to have_content user.email
  end

  scenario 'accepts new sign up with the email of an archived user' do
    archived_user = create(:user)
    archived_user.current_password = '123456'
    archived_user.archive

    fill_in 'user[email]',    with: archived_user.email
    fill_in 'user[password]', with: "123456"
    check "user_terms_and_conditions"
    click_button "Sign Up"

    new_user = User.last
    expect(new_user).not_to eq archived_user
    expect(new_user.name).to be_nil
    expect(new_user.email).to eq archived_user.email

    expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
    expect(get_me_the_cookie("l")[:value]).to eq '1'
    expect(page).to have_content I18n.t("devise.users.signed_up")
    expect(page).to have_content archived_user.email
  end
end
