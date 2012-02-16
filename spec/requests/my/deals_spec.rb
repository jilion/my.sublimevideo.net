require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature "Deal activation" do
  background do
    Factory.create(:deal, token: 'rts1', availability_scope: 'use_clients')
    Factory.create(:deal, token: 'rts2', availability_scope: 'use_clients(false)')
    Factory.create(:deal, token: 'rts3', availability_scope: 'newsletter(true)')
  end

  context "user is not logged-in" do
    background do
      @user = Factory(:user, use_clients: true)
      Factory(:site, user: @user)
    end

    scenario "deal is activated with a after-login redirect" do
      expect { go 'my', "/d/rts1" }.to_not change(DealActivation, :count)
      current_url.should eq "http://my.sublimevideo.dev/login"

      fill_in 'Email',    with: @user.email
      fill_in 'Password', with: '123456'

      expect { click_button 'Log In' }.to change(DealActivation, :count).by(1)
      current_url.should eq "http://my.sublimevideo.dev/sites"
    end
  end

  context "user has no account" do
    scenario "deal is activated through a cookie" do
      DealActivation.count.should eq 0
      expect { go 'my', "/d/rts3" }.to_not change(DealActivation, :count)
      get_me_the_cookie("d")[:value].should eq 'rts3'
      current_url.should eq "http://my.sublimevideo.dev/login"

      visit '/signup'

      fill_in "Email",    with: 'toto@titi.com'
      fill_in "Password", with: "123456"
      check "user_terms_and_conditions"
      expect { click_button 'Sign Up' }.to change(DealActivation, :count).by(1)

      current_url.should eq "http://my.sublimevideo.dev/sites/new"
      get_me_the_cookies.map { |c| c['name'] }.should_not include("d")
    end
  end

  context "user is logged-in" do
    background do
      sign_in_as :user, use_clients: true
      Factory(:site, user: @current_user)
    end

    context "and can activate the deal" do
      scenario "the deal activation is successful" do
        expect { go 'my', "/d/rts1" }.to change(DealActivation, :count).by(1)
        current_url.should eq "http://my.sublimevideo.dev/sites"
      end
    end

    context "and can't activate the deal" do
      scenario "the deal activation isn't successful" do
        expect { go 'my', "/d/rts2" }.to_not change(DealActivation, :count)
        current_url.should eq "http://my.sublimevideo.dev/sites"
      end
    end
  end

end
