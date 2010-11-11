class Users::PasswordsController < ApplicationController
  
  # POST /password/validate
  def validate
    @valid_password = current_user.valid_password?(params[:password])
    respond_to do |format|
      format.js
    end
  end
  
end
