module CustomDevisePaths

  def after_sign_in_path_for(resource_or_scope)
    if stored_path = stored_location_for(resource_or_scope)
      if stored_path =~ /^http/
        stored_path
      else
        "#{request.protocol}my.#{request.domain}#{stored_path}"
      end
    else
      case Devise::Mapping.find_scope!(resource_or_scope)
      when :user
        sites_url(subdomain: 'my')
      when :admin
        admin_sites_url(subdomain: 'admin')
      end
    end
  end

  def after_sign_up_path_for(resource_or_scope)
    case Devise::Mapping.find_scope!(resource_or_scope)
    when :user
      new_site_url(subdomain: 'my')
    when :admin
      admin_sites_url(subdomain: 'admin')
    end
  end

  # The path used after confirmation.
  def after_confirmation_path_for(resource_name, resource)
    case Devise::Mapping.find_scope!(resource)
    when :user
      if resource.created_at.to_i == resource.confirmation_sent_at.to_i
        more_user_info_url(subdomain: 'my')
      else
        sites_url(subdomain: 'my')
      end
    when :admin
      admin_sites_url(subdomain: 'admin')
    end
  end

  def after_resending_confirmation_instructions_path_for(resource_or_scope)
    after_sign_out_path_for(resource_or_scope)
  end

  def after_sending_reset_password_instructions_path_for(resource_or_scope)
    after_sign_out_path_for(resource_or_scope)
  end

  def after_update_path_for(resource_or_scope)
    [:edit, :"#{Devise::Mapping.find_scope!(resource_or_scope)}"]
  end

  def after_sign_out_path_for(resource_or_scope)
    case Devise::Mapping.find_scope!(resource_or_scope)
    when :user
      root_url(host: request.domain, protocol: 'http')
    when :admin
      send "new_#{Devise::Mapping.find_scope!(resource_or_scope)}_session", subdomain: 'admin'
    end
  end

end
