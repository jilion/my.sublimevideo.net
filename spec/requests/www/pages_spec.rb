# coding: utf-8
require 'spec_helper'

feature "Com Pages" do

  context "unlogged visitor" do
    background do
      @current_user = nil
    end

    describe "menu" do
      scenario 'links are clickable and routable' do
        go 'www', '/'

        within '#menu' do
          current_url.should eq "http://sublimevideo.dev/"

          click_link 'Features'
          current_url.should eq "http://sublimevideo.dev/features"

          click_link 'Plans'
          current_url.should eq "http://sublimevideo.dev/plans"

          click_link 'Demo'
          current_url.should eq "http://sublimevideo.dev/demo"

          VCR.use_cassette('twitter/showcase') { click_link 'Showcase' }
          current_url.should eq "http://sublimevideo.dev/customer-showcase"

          click_link 'Help'
          current_url.should eq "http://sublimevideo.dev/help"

          # click_link 'Blog'
          # current_url.should eq "http://sublimevideo.dev/blog"

          click_link 'Login'
          current_url.should eq "http://sublimevideo.dev/?p=login"

          click_link 'Sign Up'
          current_url.should eq "http://sublimevideo.dev/?p=signup"
        end
      end
    end

    describe "footer" do
      scenario 'links are clickable and routable' do
        go 'www', '/'

        within 'footer' do
          click_link 'Home'
          current_url.should eq "http://sublimevideo.dev/"

          click_link 'Features'
          current_url.should eq "http://sublimevideo.dev/features"

          click_link 'Demo'
          current_url.should eq "http://sublimevideo.dev/demo"

          click_link 'Plans & Pricing'
          current_url.should eq "http://sublimevideo.dev/plans"

          VCR.use_cassette('twitter/showcase') { click_link 'Customer Showcase' }
          current_url.should eq "http://sublimevideo.dev/customer-showcase"

          click_link 'Help'
          current_url.should eq "http://sublimevideo.dev/help"

          click_link 'Documentation'
          current_url.should eq "http://docs.sublimevideo.dev/quickstart-guide"

          click_link 'Player Releases'
          current_url.should eq "http://docs.sublimevideo.dev/releases"

          # click_link 'Blog'
          # current_url.should eq "http://sublimevideo.dev/blog"

          click_link 'Contact'
          current_url.should eq "http://sublimevideo.dev/contact"

          click_link 'About'
          current_url.should eq "http://sublimevideo.dev/about"

          click_link 'Terms & Conditions'
          current_url.should eq "http://my.sublimevideo.dev/terms"

          click_link 'Privacy Policy'
          current_url.should eq "http://my.sublimevideo.dev/privacy"
        end
      end
    end

    describe "home page" do
      scenario 'Get It Know link is reachable and show signup popup' do
        go 'www', '/'

        click_link 'Get It Now'

        current_url.should eq "http://sublimevideo.dev/?p=signup"
      end
    end

    describe "log in" do
      background do
        create_plans
        create_user user: {
          name: "John Doe",
          email: "john@doe.com",
          password: "123456"
        }
        go 'www', '/?p=login'
      end

      describe "redirections" do
        context "with www" do
          %w[login log_in sign_in signin].each do |path|
            scenario "#{path} is redirected to /?p=login" do
              go 'www', "/#{path}"
              current_url.should eq "http://sublimevideo.dev/?p=login"
            end
          end
        end

        context "without www" do
          %w[login log_in sign_in signin].each do |path|
            scenario "#{path} is redirected to /?p=login" do
              go "/#{path}"
              current_url.should eq "http://sublimevideo.dev/?p=login"
            end
          end
        end
      end

      context "With an active user" do
        scenario "log in is successful" do
          fill_in 'Email',    with: "john@doe.com"
          fill_in 'Password', with: '123456'
          click_button 'Log In'

          current_url.should eq "http://my.sublimevideo.dev/sites/new"
        end

        scenario "displays errors if log in is not successful" do
          fill_in 'Email',    with: ''
          fill_in 'Password', with: ''
          click_button 'Log In'

          current_url.should eq "http://my.sublimevideo.dev/login"
          page.should have_content "Invalid email or password"
        end
      end

      context "With a suspended user" do
        background do
          @current_user.suspend
        end

        scenario "suspended user" do
          fill_in "Email",    with: "john@doe.com"
          fill_in "Password", with: "123456"
          click_button 'Log In'

          current_url.should eq "http://my.sublimevideo.dev/suspended"
        end
      end

      context "With an archived user" do
        background do
          @current_user.skip_pwd { @current_user.archive }
        end

        scenario "archived user" do
          fill_in "Email",    with: "john@doe.com"
          fill_in "Password", with: "123456"
          click_button 'Log In'

          current_url.should eq "http://my.sublimevideo.dev/login"
        end
      end

    end

    describe "sign up" do
      background do
        create_plans
        go 'www', '/?p=signup'
      end

      describe "redirections" do
        context "with www" do
          %w[signup register sign_up].each do |path|
            scenario "#{path} is redirected to /?p=signup" do
              go 'www', "/#{path}"
              current_url.should eq "http://sublimevideo.dev/?p=signup"
            end
          end
        end

        context "without www" do
          %w[signup register sign_up].each do |path|
            scenario "#{path} is redirected to /?p=signup" do
              go "/#{path}"
              current_url.should eq "http://sublimevideo.dev/?p=signup"
            end
          end
        end
      end

      scenario "it's possible to sign up" do
        fill_in 'Email',    with: 'remy@jilion.com'
        fill_in 'Password', with: '123456'
        check "user_terms_and_conditions"
        click_button 'Sign Up'

        current_url.should eq "http://my.sublimevideo.dev/sites/new"
      end

      context "with the email of an archived user" do
        background do
          @archived_user = create(:user)
          @archived_user.skip_pwd { @archived_user.archive }
        end

        scenario "archived user" do
          fill_in 'Email',    with: @archived_user.email
          fill_in 'Password', with: '123456'
          check "user_terms_and_conditions"
          click_button 'Sign Up'

          current_url.should eq "http://my.sublimevideo.dev/sites/new"
          User.last.should_not eq @archived_user
        end
      end

      scenario "displays errors if sign up is not successful" do
        go 'www', '/?p=signup'

        fill_in 'Email',    with: ''
        fill_in 'Password', with: ''
        click_button 'Sign Up'

        current_url.should eq "http://my.sublimevideo.dev/signup"
        page.should have_content "Email can't be blank"
        page.should have_content "Password can't be blank"
        page.should have_content "Terms & Conditions must be accepted"
      end
    end
  end

  context "logged-in user" do
    background do
      create_plans
      sign_in_as :user
    end

    describe "redirections" do
      pending 'home is not reachable' do # pending because this done via is made in JS
        go 'www', '/'
        current_url.should eq "http://my.sublimevideo.dev/sites/new"
      end

      pending 'help is redirected' do # pending because this done via is made in JS
        go 'www', '/help'
        current_url.should eq "http://my.sublimevideo.dev/help"
      end

      %w[privacy terms sites account].each do |path|
        scenario "#{path} is redirected to 'my'" do
          go 'www', "/#{path}"
          current_url.should =~ /http:\/\/my\.sublimevideo\.dev\/#{path}/
        end
      end

      %w[javascript-api releases].each do |path|
        scenario "#{path} is redirected to 'docs'" do
          go 'www', "/#{path}"
          current_url.should =~ /http:\/\/docs\.sublimevideo\.dev\/#{path}/
        end
      end

    end

    describe "menu" do
      scenario 'links are clickable and routable' do
        within '#menu' do
          page.should have_no_content 'Features'
          page.should have_no_content 'Plans'
          page.should have_no_content 'Demo'
          page.should have_no_content 'Showcase'
          page.should have_no_content 'Blog'
          page.should have_no_content 'Login'

          page.should have_content 'Logout'
          page.should have_content @current_user.name
        end
      end
    end

    describe "footer" do
      pending 'home link is hidden' do # pending because this done via is made in JS
        within 'footer' do
          page.should have_no_content 'Home'
        end
      end
    end
  end

end
