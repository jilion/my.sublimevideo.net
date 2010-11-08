class Users::PasswordsController < ApplicationController
  
  # POST /passwords/validate
  def validate
    if current_user.valid_password?(params[:password])
      head :ok
    else
      head :forbidden
    end
  end
  
end
