module RedirectionFilters
  
  def redirect_suspended_user
    redirect_to page_path('suspended') if current_user.suspended?
  end
  
  def redirect_wrong_password(resource)
    if params[:user].blank? || !current_user.valid_password?(params[:user][:current_password])
      flash[:alert] = "The given password is invalid!"
      route = case resource.class.to_s
      when 'User'
        edit_user_registration_path
      else
        [:edit, resource]
      end
      redirect_to route and return
    end
  end
  
end