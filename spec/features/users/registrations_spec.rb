require 'spec_helper'

feature 'Sign Up' do
  background do
    go 'my', '/signup'
    current_url.should eq "http://my.sublimevideo.dev/signup"
  end

  scenario 'display errors if any' do
    fill_in 'user[email]',    with: 'user@example.org'
    fill_in 'user[password]', with: "123456"
    click_button "Sign Up"

    current_url.should eq "http://my.sublimevideo.dev/signup"
    page.should have_content 'Terms & Conditions must be accepted'

    fill_in "Password", with: "123456"
    check "user_terms_and_conditions"
    click_button "Sign Up"

    user = User.last
    user.name.should be_nil
    user.email.should eq 'user@example.org'

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    get_me_the_cookie("l")[:value].should eq '1'
    page.should have_content I18n.t("devise.users.signed_up")
    page.should have_content user.email
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
    new_user.should_not eq archived_user
    new_user.name.should be_nil
    new_user.email.should eq archived_user.email

    current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
    get_me_the_cookie("l")[:value].should eq '1'
    page.should have_content I18n.t("devise.users.signed_up")
    page.should have_content archived_user.email
  end
end
