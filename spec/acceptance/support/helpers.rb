module HelperMethods
  
  def warden
    request.env['warden']
  end
  
  def create_user(options={})
    @current_user ||= begin
      user = Factory(:user, options[:user] || {})
      user.confirm! unless options[:confirm] == false
      user.lock! if options[:locked] == true
      user
    end
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
  
end

Rspec.configuration.include(HelperMethods)