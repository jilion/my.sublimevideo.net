module ControllerHelpers
  module CustomDevisePaths

    def after_sign_in_path_for(resource_or_scope)
      if stored_path = stored_location_for(resource_or_scope)
        if stored_path =~ /^http/
          stored_path
        else
          my_url(stored_path)
        end
      else
        case Devise::Mapping.find_scope!(resource_or_scope)
        when :user
          sites_url
        when :admin
          admin_sites_url
        end
      end
    end

    def after_sign_up_path_for(resource_or_scope)
      case Devise::Mapping.find_scope!(resource_or_scope)
      when :user
        new_site_url
      when :admin
        admin_sites_url
      end
    end

    # The path used after confirmation.
    def after_confirmation_path_for(resource_name, resource)
      case Devise::Mapping.find_scope!(resource)
      when :user
        if (resource.confirmation_sent_at.to_i - resource.created_at.to_i) <= 30
          more_user_info_url
        else
          sites_url
        end
      when :admin
        admin_sites_url
      end
    end

    def after_resending_confirmation_instructions_path_for(resource_or_scope)
      after_sign_out_path_for(resource_or_scope)
    end

    def after_sending_reset_password_instructions_path_for(resource_or_scope)
      login_user_url
    end

    def after_update_path_for(resource_or_scope)
      [:edit, :"#{Devise::Mapping.find_scope!(resource_or_scope)}"]
    end

    def after_sign_out_path_for(resource_or_scope)
      case Devise::Mapping.find_scope!(resource_or_scope)
      when :user
        layout_url('')
      when :admin
        new_admin_session
      end
    end

  end
end
