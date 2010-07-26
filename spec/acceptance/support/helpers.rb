module HelperMethods
  
  def warden
    request.env['warden']
  end
  
  def create_user(options={})
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
  
  def create_admin(options={})
    @current_admin ||= begin
      admin = Factory(:admin, options[:admin] || {})
      admin.accept_invitation unless options[:accept_invitation] == false
      admin.lock! if options[:locked] == true
      admin
    end
  end
  
  def sign_in_as(resource_name, options={}, &block)
    send(:"sign_in_as_#{resource_name}", { resource_name => options }, &block)
  end
  
  def sign_in_as_user(options={}, &block)
    user = create_user(options)
    visit "/login"
    fill_in 'Email',    :with => user.email
    fill_in 'Password', :with => '123456'
    check   'Remember me' if options[:remember_me] == true
    yield if block_given?
    click_button 'Login'
    user
  end
  
  def sign_in_as_admin(options={}, &block)
    admin = create_admin(options)
    visit "/admin/login"
    fill_in 'Email',    :with => admin.email
    fill_in 'Password', :with => '123456'
    check   'Remember me' if options[:remember_me] == true
    yield if block_given?
    click_button 'Login'
    admin
  end
  
  def sign_out
    click "Logout"
  end
  
end

Rspec.configuration.include(HelperMethods)