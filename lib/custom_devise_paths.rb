module CustomDevisePaths
  def after_update_path_for(resource)
    if resource == :user || resource.is_a?(User)
      edit_user_registration_url
    elsif resource == :admin || resource.is_a?(Admin)
      edit_admin_registration_url
    end
  end
  
  def after_sign_in_path_for(resource)
    if resource == :user || resource.is_a?(User)
      sites_path
    elsif resource == :admin || resource.is_a?(Admin)
      admin_profiles_url
    end
  end
  
  def after_sign_out_path_for(resource)
    if resource == :user || resource.is_a?(User)
      new_user_session_url
    elsif resource == :admin || resource.is_a?(Admin)
      new_admin_session_url
    end
  end
end