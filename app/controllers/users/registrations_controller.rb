class Users::RegistrationsController < Devise::RegistrationsController
  include RedirectionFilters
  before_filter :redirect_suspended_user

  def destroy
    @user = User.find(current_user.id)
    @user.current_password = params[:user] && params[:user][:current_password]

    respond_with(@user) do |format|
      if @user.archive
        format.html { sign_out_and_redirect(@user) }
      else
        format.html { render 'users/registrations/edit' }
      end
    end
  end

end
