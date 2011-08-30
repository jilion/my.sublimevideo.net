module Spec
  module Support
    module RequestsHelpers

      def warden
        request.env['warden']
      end

      def create_plans
        plans_attributes = [
          { name: "free",        cycle: "none",  player_hits: 0,          price: 0 },
          { name: "sponsored",  cycle: "none",  player_hits: 0,          price: 0 },
          { name: "comet",      cycle: "month", player_hits: 3_000,      price: 990 },
          { name: "planet",     cycle: "month", player_hits: 50_000,     price: 1990 },
          { name: "star",       cycle: "month", player_hits: 200_000,    price: 4990 },
          { name: "galaxy",     cycle: "month", player_hits: 1_000_000,  price: 9990 },
          { name: "comet",      cycle: "year",  player_hits: 3_000,      price: 9900 },
          { name: "planet",     cycle: "year",  player_hits: 50_000,     price: 19900 },
          { name: "star",       cycle: "year",  player_hits: 200_000,    price: 49900 },
          { name: "galaxy",     cycle: "year",  player_hits: 1_000_000,  price: 99900 },
          { name: "custom1",    cycle: "year",  player_hits: 10_000_000, price: 999900 }
        ]
        plans_attributes.each { |attributes| Plan.create(attributes) }
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
          user = if options[:without_cc] == true
            FactoryGirl.create(:user_no_cc, options[:user] || {})
          else
            attrs = Factory.attributes_for(:user)
            user = FactoryGirl.build(:user_real_cc, (options[:user] || {}).merge({
              cc_brand: options[:cc_type],
              cc_full_name: "#{attrs[:first_name]} #{attrs[:last_name]}",
              cc_number: options[:cc_number],
              cc_verification_value: "111",
              cc_expiration_month: options[:cc_expire_on].month,
              cc_expiration_year: options[:cc_expire_on].year
            }))
            user.save!(validate: (options[:cc_expire_on] < Time.now ? false : true))
            user.apply_pending_credit_card_info
            user
          end
          user.confirm! if !!options[:confirm]
          user.lock! if !!options[:locked]
          user
        end
        @current_user
      end

      def create_admin(options = {})
        options[:accept_invitation] = options[:admin].delete(:accept_invitation) || options[:accept_invitation]
        options[:locked]            = options[:admin].delete(:locked) || options[:locked]

        @current_admin ||= begin
          admin = FactoryGirl.create(:admin, options[:admin] || {})
          admin.accept_invitation if options[:accept_invitation] == true
          admin.lock! if options[:locked] == true
          admin
        end
      end

      def set_credit_card(options={})
        choose  "user_cc_brand_#{options[:type] || 'visa'}"
        fill_in "Name on card", :with => 'Jime'
        fill_in "Card number", :with => options[:d3d] ? "4000000000000002" : (options[:type] == 'master' ? "5399999999999999" : "4111111111111111")
        select  "#{options[:expire_on_month] || "6"}", :from => "#{options[:expire_on_prefix] || "user"}_cc_expiration_month"
        select  "#{options[:expire_on_year] || Time.now.year + 1}", :from => "#{options[:expire_on_prefix] || "user"}_cc_expiration_year"
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

RSpec.configuration.include(Spec::Support::RequestsHelpers, :type => :request)