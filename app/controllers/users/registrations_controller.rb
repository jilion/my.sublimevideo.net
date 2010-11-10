class Users::RegistrationsController < Devise::RegistrationsController
  
  before_filter :redirect_wrong_password_for_user!, :only => [:update, :destroy]
  
private
  
  def redirect_wrong_password_for_user!
    redirect_wrong_password(resource, params[:password])
  end
  
end