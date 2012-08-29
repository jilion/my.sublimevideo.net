module Spec
  module Support
    module RequestsHelpers

      def warden
        request.env['warden']
      end

      def create_user(options={})
        options[:user] = {} unless options[:user]

        options[:confirm]    = options[:user].delete(:confirm) || options[:confirm]
        options[:without_cc] = options[:user].delete(:without_cc) || options[:without_cc]
        options[:locked]     = options[:user].delete(:locked) || options[:locked]
        options[:cc_type]    = options[:user].delete(:cc_type) || options[:cc_type] || 'visa'
        options[:cc_number]  = options[:user].delete(:cc_number) || card_number(options[:cc_type])
        options[:suspend]    = options[:user].delete(:suspend) || options[:suspend]
        cc_expire_on = options[:user].delete(:cc_expire_on) || options[:cc_expire_on] || 2.years.from_now

        @current_user = if options[:without_cc] == true
          create(:user_no_cc, options[:user] || {})
        else
          attrs = FactoryGirl.attributes_for(:user)
          user = create(:user, (options[:user] || {}).merge({
            cc_type:        options[:cc_type],
            cc_full_name:   attrs[:billing_name],
            cc_last_digits: options[:cc_number][-4,4]
          }))
          if cc_expire_on <= Time.now.utc.end_of_month.to_date
            user.cc_expire_on = cc_expire_on.end_of_month.to_date
            user.skip_password(:save!)
          end
          user
        end
        @current_user.confirm! if !!options[:confirm]
        @current_user.lock! if !!options[:locked]

        @current_user
      end

      def create_admin(options = {})
        options[:accept_invitation] = options[:admin].delete(:accept_invitation) || options[:accept_invitation]
        options[:locked]            = options[:admin].delete(:locked) || options[:locked]

        @current_admin ||= begin
          admin = create(:admin, options[:admin] || {})
          admin.accept_invitation if options[:accept_invitation] == true
          admin.lock! if options[:locked] == true
          admin
        end
      end

      def set_credit_card(options = {})
        choose  "user_cc_brand_#{options[:type] == 'master' ? 'master' : 'visa'}"
        fill_in "Name on card", with: 'Jilion Team'
        fill_in "Card number", with: card_number(options[:type])
        select  "#{options[:expire_on_month] || "6"}", from: "#{options[:expire_on_prefix] || 'user'}_cc_expiration_month"
        select  "#{options[:expire_on_year] || Time.now.year + 1}", from: "#{options[:expire_on_prefix] || "user"}_cc_expiration_year"
        fill_in "Security Code", with: '111'
      end

      def set_credit_card_in_site_form(options = {})
        set_credit_card(options.merge(expire_on_prefix: "site_user_attributes"))
      end

      def card_number(type = 'visa')
        case type
        when 'visa'
          '4111111111111111'
        when 'master'
          '5399999999999999'
        when 'd3d'
          '4000000000000002'
        end
      end

      def last_digits(type = 'visa')
        card_number(type)[-4,4]
      end

      # http://stackoverflow.com/questions/4484435/rails3-how-do-i-visit-a-subdomain-in-a-steakrspec-spec-using-capybara
      def switch_to_subdomain(subdomain = nil)
        subdomain += '.' if subdomain.present?
        if Capybara.current_driver == :rack_test
          Capybara.app_host = "http://#{subdomain}#{$capybara_domain}"
        else
          Capybara.app_host = "http://#{subdomain}#{$capybara_domain}:#{Capybara.server_port}"
        end
      end

      def go(*subdomain_and_route)
        if subdomain_and_route.one?
          switch_to_subdomain(nil)
          visit *subdomain_and_route
        else
          switch_to_subdomain(subdomain_and_route[0])
          visit subdomain_and_route[1].start_with?("/") ? subdomain_and_route[1] : "/#{subdomain_and_route[1]}"
        end
      end

      def sign_in_as(resource_name, options = {})
        kill_user = options.delete(:kill_user)
        sign_out(kill_user) if @current_user
        options = { resource_name => options }

        resource = case resource_name
        when :user
          go 'my', '/login'
          create_user(options)
        when :admin
          go 'admin', '/login'
          create_admin(options)
        end
        fill_in 'Email',    with: resource.email
        fill_in 'Password', with: options[resource_name][:password] || '123456'
        check   'Remember me' if options[:remember_me] == true
        yield if block_given?
        click_button 'Log In'
        resource
      end

      def send_invite_to(resource_name, email = "invited@invited.com")
        sign_in_as :admin
        go 'admin', "/#{resource_name.to_sym == :admin ? '' : "/#{resource_name.to_s.pluralize}"}invitation/new"
        fill_in 'Email', with: email
        yield if block_given?
        click_button 'Send'
        sign_out
        resource_name.to_s.classify.constantize.last
      end

      def sign_out(kill_user = false)
        click_link "logout"
        @current_user = nil #if kill_user
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::RequestsHelpers, type: :request)
