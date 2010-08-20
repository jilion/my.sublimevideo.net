module HelperMethods
  
  def warden
    request.env['warden']
  end
  
  def create_user(options = {})
    options[:confirm]    = options[:user].delete(:confirm) || options[:confirm]
    options[:without_cc] = options[:user].delete(:without_cc) || options[:without_cc]
    options[:locked]     = options[:user].delete(:locked) || options[:locked]
    
    @current_user ||= begin
      user = Factory(:user, options[:user] || {})
      user.confirm! unless options[:confirm] == false
      user.lock! if options[:locked] == true
      unless options[:without_cc] == true
        user.update_attribute(:cc_type, 'visa')
        user.update_attribute(:cc_last_digits, 123)
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
  
  def sign_in_as(resource_name, options = {}, &block)
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
  
  def send_invite_to(resource_name, email = "invited@invited.com", &block)
    sign_in_as :admin
    visit "/admin/#{resource_name.to_s.pluralize}/invitation/new"
    fill_in 'Email', :with => email
    yield if block_given?
    click_button 'Send'
    sign_out
    resource_name.to_s.classify.constantize.last
  end
  
  def sign_out
    click "Logout"
  end
  
end

Rspec.configuration.include(HelperMethods)