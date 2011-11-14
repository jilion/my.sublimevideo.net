class My::Users::RegistrationsController < Devise::RegistrationsController
  include MyRedirectionFilters

  before_filter :redirect_suspended_user

  def destroy
    @user = User.find(current_user.id)
    @user.current_password = params[:user] && params[:user][:current_password]

    respond_with(@user) do |format|
      if @user.archive
        format.html do
          sign_out(@user)
          redirect_to new_user_session_path, :notice => I18n.t("devise.registrations.destroyed")
        end
      else
        format.html { render 'users/registrations/edit' }
      end
    end
  end

  def after_update_path_for(resource_or_scope)
    [:edit, :"#{Devise::Mapping.find_scope!(resource_or_scope)}_registration"]
  end

end
