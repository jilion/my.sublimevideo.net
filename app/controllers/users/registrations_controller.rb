class Users::RegistrationsController < Devise::RegistrationsController
  include RedirectionFilters
  before_filter :redirect_suspended_user

  def destroy
    @user = User.find(current_user.id)
    @user.current_password = params[:user] && params[:user][:current_password]
    @user.archive
    sign_out_and_redirect(@user)
  end

end
