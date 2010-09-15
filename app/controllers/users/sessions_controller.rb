class Users::SessionsController < Devise::SessionsController
  
  # POST /users/sign_in
  def create
    params[:user][:email].downcase! if params[:user] && params[:user][:email]
    super
  end
  
end
