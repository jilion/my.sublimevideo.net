module Spec
  module Support
    module AcceptanceHelpers

      def warden
        request.env['warden']
      end

      def create_user(options = {})
        options[:confirm]      = options[:user].delete(:confirm) || options[:confirm]
        options[:without_cc]   = options[:user].delete(:without_cc) || options[:without_cc]
        options[:locked]       = options[:user].delete(:locked) || options[:locked]
        options[:cc_type]      = options[:user].delete(:cc_type) || options[:cc_type] || 'visa'
        options[:cc_number]    = options[:user].delete(:cc_number) || (options[:cc_type] == 'visa' ? "4111111111111111" : "5399999999999999")
        options[:cc_expire_on] = options[:user].delete(:cc_expire_on) || options[:cc_expire_on] || 2.years.from_now
        options[:suspend]      = options[:user].delete(:suspend) || options[:suspend]

        @current_user ||= begin
          user = Factory(:user, options[:user] || {})
          user.confirm! if !!options[:confirm]
          if options[:without_cc] == true
            user.reset_credit_card_info
            user.save!
          else
            user.attributes = {
              cc_type: options[:cc_type],
              cc_full_name: user.full_name,
              cc_number: options[:cc_number],
              cc_verification_value: "111",
              cc_expire_on: options[:cc_expire_on]
            }
            user.cc_last_digits = options[:cc_number][-4,4] # can't be mass-assigned
            VCR.use_cassette('ogone/visa_authorize_1_alias') { user.check_credit_card }
            user.save!(validate: (options[:cc_expire_on] < Time.now ? false : true))
          end
          user.lock! if !!options[:locked]
          user
        end
        @current_user
      end

      def create_admin(options = {})
        options[:accept_invitation] = options[:admin].delete(:accept_invitation) || options[:accept_invitation]
        options[:locked]            = options[:admin].delete(:locked) || options[:locked]

        @current_admin ||= begin
          admin = Factory(:admin, options[:admin] || {})
          admin.accept_invitation if options[:accept_invitation] == true
          admin.lock! if options[:locked] == true
          admin
        end
      end

      def set_credit_card(options={})
        choose "user_cc_type_#{options[:type] || 'visa'}"
        fill_in "Name on card", :with => 'Jime'
        fill_in "Card number", :with => options[:d3d] ? "4000000000000002" : (options[:type] == 'master' ? "5399999999999999" : "4111111111111111")
        select "#{options[:expire_on_month] || "6"}", :from => "#{options[:expire_on_prefix] || "user"}_cc_expire_on_2i"
        select "#{options[:expire_on_year] || Time.now.year + 1}", :from => "#{options[:expire_on_prefix] || "user"}_cc_expire_on_1i"
        fill_in "Security Code", :with => '111'
      end

      def set_credit_card_in_site_form(options={})
        set_credit_card(options.merge(:expire_on_prefix => "site_user_attributes"))
      end

      def sign_in_as(resource_name, options={})
        options = { resource_name => options }
        resource = case resource_name
        when :user
          visit "/login"
          create_user(options)
        when :admin
          visit "/admin/login"
          create_admin(options)
        end
        fill_in 'Email',    :with => resource.email
        fill_in 'Password', :with => '123456'
        check   'Remember me' if options[:remember_me] == true
        yield if block_given?
        click_button 'Login'
        resource
      end

      def send_invite_to(resource_name, email = "invited@invited.com")
        sign_in_as :admin
        visit "/admin/#{resource_name.to_s.pluralize}/invitation/new"
        fill_in 'Email', :with => email
        yield if block_given?
        click_button 'Send'
        sign_out
        resource_name.to_s.classify.constantize.last
      end

      def sign_out
        click_link_or_button "Logout"
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::AcceptanceHelpers, :type => :request)