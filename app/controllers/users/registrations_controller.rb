class Users::RegistrationsController < Devise::RegistrationsController
  include RedirectionFilters

  before_filter :redirect_suspended_user
  before_filter :only => [:update, :destroy] do |controller|
    redirect_wrong_password_to(edit_user_registration_path)
  end

  def destroy
    @user = User.find(current_user.id)
    @user.archive
    sign_out_and_redirect(@user)
  end

end
