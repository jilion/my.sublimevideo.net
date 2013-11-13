require 'spec_helper'
include ActionView::Helpers::SanitizeHelper

feature 'Deal activation' do
  background do
    create(:deal, token: 'rts1', availability_scope: 'vip')
    create(:deal, token: 'rts2', availability_scope: 'vip(false)')
    create(:deal, token: 'rts3', availability_scope: 'with_cc')
  end

  context 'user is not logged-in' do
    background do
      @user = create(:user, vip: true)
      SiteManager.new(build(:site, user: @user)).create
    end

    scenario 'deal is activated with a after-login redirect' do
      expect { go 'my', '/d/rts1' }.to_not change(DealActivation, :count)
      expect(current_url).to eq 'http://my.sublimevideo.dev/login'

      fill_in 'user[email]',    with: @user.email
      fill_in 'user[password]', with: '123456'

      expect { click_button 'Log In' }.to change(DealActivation, :count).by(1)
      expect(current_url).to eq 'http://my.sublimevideo.dev/sites'
    end
  end

  context 'user has no account' do
    scenario 'deal is activated through a cookie' do
      expect(DealActivation.count).to eq 0
      expect { go 'my', '/d/rts3' }.to_not change(DealActivation, :count)
      expect(get_me_the_cookie('d')[:value]).to eq 'rts3'
      expect(current_url).to eq 'http://my.sublimevideo.dev/login'

      visit '/signup'
      expect(get_me_the_cookie('d')[:value]).to eq 'rts3'

      fill_in 'user[email]',    with: 'toto@titi.com'
      fill_in 'user[password]', with: '123456'
      check 'user[terms_and_conditions]'

      expect { click_button 'Sign Up' }.to_not change(DealActivation, :count)

      User.last.update_columns(
        cc_expire_on: 2.years.from_now,
        cc_last_digits: '1234',
        cc_type: 'visa'
      )

      expect(current_url).to eq 'http://my.sublimevideo.dev/assistant/new-site'
      expect(get_me_the_cookie('d')[:value]).to eq 'rts3'

      expect { visit '/sites' }.to change(DealActivation, :count).by(1)

      expect(current_url).to eq 'http://my.sublimevideo.dev/assistant/new-site'
      expect(get_me_the_cookies.map { |c| c['name'] }).not_to include('d')
    end
  end

  context 'user is logged-in' do
    background do
      sign_in_as :user, vip: true
      SiteManager.new(build(:site, user: @current_user)).create
    end

    context 'and can activate the deal' do
      scenario 'the deal activation is successful' do
        expect { go 'my', '/d/rts1' }.to change(DealActivation, :count).by(1)
        expect(current_url).to eq 'http://my.sublimevideo.dev/sites'
      end
    end

    context "and can't activate the deal" do
      scenario "the deal activation isn't successful" do
        expect { go 'my', '/d/rts2' }.to_not change(DealActivation, :count)
        expect(current_url).to eq 'http://my.sublimevideo.dev/sites'
      end
    end
  end

end
