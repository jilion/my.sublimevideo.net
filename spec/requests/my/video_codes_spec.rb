# coding: utf-8
require 'spec_helper'

feature "Video code generator" do

  scenario "return to this page if user click on the 'Log In' link inside the page" do
    user = create_user

    go 'my', "/video-code-generator"

    current_url.should eq "http://my.sublimevideo.dev/video-code-generator"

    within '#login_needed_for_iframe_embed' do
      click_link "Log In"
    end

    current_url.should eq "http://my.sublimevideo.dev/login?user_return_to=%2Fvideo-code-generator"
    fill_in "Email",    with: user.email
    fill_in "Password", with: "123456"
    click_button "Log In"

    current_url.should eq "http://my.sublimevideo.dev/video-code-generator"
  end

end
