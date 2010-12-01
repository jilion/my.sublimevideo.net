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
        options[:cc_expire_on] = options[:user].delete(:cc_expire_on) || options[:cc_expire_on] || 2.years.from_now
        
        @current_user ||= begin
          user = Factory(:user, options[:user] || {})
          user.confirm! unless options[:confirm] == false
          user.lock! if options[:locked] == true
          unless options[:without_cc] == true
            user.attributes = { :cc_type => options[:cc_type], :cc_expire_on => options[:cc_expire_on] }
            user.cc_last_digits = 1234 # can't be mass-assigned
            user.save(:validate => false)
          end
          user
        end
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
      
      def sign_in_as(resource_name, options = {})
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

RSpec.configuration.include(Spec::Support::AcceptanceHelpers)