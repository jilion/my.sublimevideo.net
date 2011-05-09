module CustomDevisePaths

  def after_sign_in_path_for(resource_or_scope)
    case Devise::Mapping.find_scope!(resource_or_scope)
    when :user
      sites_path
    when :admin
      admin_delayed_jobs_url
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    [:new, :"#{Devise::Mapping.find_scope!(resource_or_scope)}_session"]
  end

  def after_update_path_for(resource_or_scope)
    [:edit, :"#{Devise::Mapping.find_scope!(resource_or_scope)}_registration"]
  end

end
