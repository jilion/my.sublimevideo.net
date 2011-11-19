module CustomDevisePaths

  def after_sign_in_path_for(resource_or_scope)
    case Devise::Mapping.find_scope!(resource_or_scope)
    when :user
      sites_url(subdomain: 'my')
    when :admin
      admin_sites_url(subdomain: 'admin')
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    case Devise::Mapping.find_scope!(resource_or_scope)
    when :user
      root_url(host: request.domain)
    when :admin
      send "new_#{Devise::Mapping.find_scope!(resource_or_scope)}_session", subdomain: 'admin'
    end
  end

end
