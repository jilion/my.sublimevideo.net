module ControllerHelpers
  module RedirectionFilters

    def redirect_suspended_user
      redirect_to page_url('suspended') and return if user_signed_in? && current_user.suspended?
    end

    def redirect_wrong_password_to(url)
      if params[:user].blank? || !current_user.valid_password?(params[:user][:current_password])
        flash[:alert] = "The given password is invalid!"
        redirect_to url and return
      end
    end

  end
end
