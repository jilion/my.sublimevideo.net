class Users::RegistrationsController < Devise::RegistrationsController
  
  before_filter :redirect_register, :only => [:new, :create]
  
protected
  
  def redirect_register
    redirect_to user_signed_in? ? sites_path : new_user_session_path
  end
  
end