# coding: utf-8
require 'spec_helper'

feature "Referrer" do

  context "user signup after be redirected" do

    scenario "set user.referrer_site_token" do
      go '/r/b/site1234'
      current_url.should eq "http://sublimevideo.net/"
      go '/?p=signup'

      fill_in "Name",     with: "Thibaud Guillaume-Gentil"
      fill_in "Email",    with: "thibaud@jilion.com"
      fill_in "Password", with: "123456"
      check "user_terms_and_conditions"
      click_button "Sign Up"

      new_user = User.last
      new_user.referrer_site_token.should eq 'site1234'
    end

  end
end
