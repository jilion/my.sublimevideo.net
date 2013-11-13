module Spec
  module Support
    module FeaturesHelpers

      def warden
        request.env['warden']
      end

      def fill_billing_address(options = {})
        options.reverse_merge!(email: 'bob@doe.com', name: 'Bob Doe',
                               street1: '42 Abey Road', street2: '',
                               zip: '42666', city: 'New York',
                               region: 'New York', country: 'United States')

        within('#billing_address') do
          fill_in "Billing email address", with: options[:email]
          fill_in "Name",                  with: options[:name]
          fill_in "Street 1",              with: options[:street1]
          fill_in "Street 2",              with: options[:street2]
          fill_in "Zip or Postal Code",    with: options[:zip]
          fill_in "City",                  with: options[:city]
          fill_in "Region",                with: options[:region]
          select  options[:country],       from: 'Country'
        end

        yield if block_given?

        options
      end

      def fill_and_submit_billing_address(*args)
        fill_billing_address(*args) do
          click_button 'billing_info_submit'
        end
      end

      def fill_credit_card(options = {})
        options.reverse_merge!(type: 'visa', expire_on_month: 6,
                               expire_on_year: Time.now.year + 1,
                               expire_on_prefix: 'user')

        within('#credit_card') do
          choose  "user_cc_brand_#{options[:type] == 'd3d' ? 'visa' : options[:type]}"
          fill_in 'Name on card', with: 'Jilion Team'
          fill_in 'Card number', with: card_number(options[:type])
          select  sprintf("%02d", options[:expire_on_month]), from: "#{options[:expire_on_prefix]}[cc_expiration_month]"
          select  options[:expire_on_year], from: "#{options[:expire_on_prefix]}[cc_expiration_year]"
          fill_in 'Security Code', with: '111'
        end
      end

      def last_digits(type)
        card_number(type)[-4,4]
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

      def sign_in_as(resource_or_resource_name, options = {})
        sign_out if @current_user
        resource_options = { resource_or_resource_name => options }

        resource = case resource_or_resource_name
        when :user
          create_user(resource_options)
        when :user_with_site
          create_user(resource_options).tap { |u| create_site_for(u) }
        when :user_with_sites
          create_user(resource_options).tap { |u| 2.times { create_site_for(u) } }
        when :user_with_aliased_cc
          @current_user = create(:user_no_cc, valid_cc_attributes).reload
        when :admin
          create_admin(resource_options)
        end

        sign_in(resource.class == Admin ? 'admin' : 'my', resource, options)
        resource
      end

      def fill_and_submit_login(resource, options = {})
        fill_in (resource.class == Admin ? 'admin[email]' : 'user[email]'), with: resource.email
        fill_in 'Password', with: options[:password] || '123456'
        check   'Remember me' if options[:remember_me] == true
        yield if block_given?
        click_button 'Log In'
      end

      private

      # http://stackoverflow.com/questions/4484435/rails3-how-do-i-visit-a-subdomain-in-a-steakrspec-spec-using-capybara
      def switch_to_subdomain(subdomain = nil)
        subdomain += '.' if subdomain.present?
        if Capybara.current_driver == :rack_test
          Capybara.app_host = "http://#{subdomain}#{$capybara_domain}"
        else
          Capybara.app_host = "http://#{subdomain}#{$capybara_domain}:#{Capybara.server_port}"
        end
      end

      def create_user(options = {})
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
            user.save!
          end
          user
        end
        @current_user.confirm! if !!options[:confirm]
        @current_user.lock! if !!options[:locked]

        @current_user
      end

      def card_number(type = 'visa')
        send("valid_cc_attributes_#{type}")[:cc_number]
      end

      def create_site_for(user)
        SiteManager.new(build(:site, user: user)).create
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

      def send_invite_to(resource_name, email = "invited@invited.com")
        sign_in_as :admin
        go 'admin', "/#{resource_name.to_sym == :admin ? '' : "/#{resource_name.to_s.pluralize}"}invitation/new"
        fill_in 'Email', with: email
        yield if block_given?
        click_button 'Send'
        sign_out('admin')
        resource_name.to_s.classify.constantize.last
      end

      def sign_in(subdomain = 'my', *args)
        resource = args.shift
        go subdomain, '/login'
        fill_and_submit_login(resource, args.extract_options!)
      end

      def sign_out(subdomain = 'my')
        go subdomain, '/logout'
        if subdomain == 'admin'
          @current_admin = nil
        else
          @current_user = nil
        end
      end

    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::FeaturesHelpers, type: :feature

  config.before :each, type: :feature do
    allow(SiteAdminStat).to receive(:total_admin_starts) { 1 }
  end
end
