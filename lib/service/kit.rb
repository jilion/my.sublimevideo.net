module Service
  Kit = Struct.new(:kit) do

    def create(params)
      ::Kit.transaction do
        set_addons_settings(params.delete(:addons))
        kit.save!

        kit.site.touch(:settings_updated_at)
        Service::Settings.delay.update_all_types!(kit.site_id)
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    # params => { "<addon_name>" => { "settingKey" => "<value>" }
    def update(params)
      ::Kit.transaction do
        set_addons_settings(params.delete(:addons))
        kit.update_attributes!(params, as: :admin)

        kit.site.touch(:settings_updated_at)
      end
      Service::Settings.delay.update_all_types!(kit.site_id)
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def set_addons_settings(new_addons_settings = {})
      kit.settings = sanitize_new_addons_settings(new_addons_settings)
    end

    def sanitize_new_addons_settings(new_addons_settings)
      new_addons_settings.each do |addon_name, new_addon_settings|
        addon_plan = kit.site.addon_plan_for_addon_name(addon_name)
        if settings_template = addon_plan.settings_template_for(kit.design).try(:template)
          new_addon_settings.each do |new_addon_setting_key, new_addon_setting_value|
            if setting_template = settings_template[new_addon_setting_key.to_sym]
              case setting_template[:type]
              when 'float'
                check_number_inclusion(new_addon_setting_value, (setting_template[:range][0]..setting_template[:range][1]))
                new_addons_settings[addon_name][new_addon_setting_key.to_sym] = new_addon_setting_value.to_f.round(2)
              when 'boolean', 'string'
                new_addons_settings[addon_name][new_addon_setting_key.to_sym] = cast_boolean(new_addon_setting_value) if setting_template[:type] == 'boolean'
                check_string_inclusion(new_addons_settings[addon_name][new_addon_setting_key.to_sym], setting_template[:values])
              end
            else
              new_addon_settings.delete(new_addon_setting_key)
            end
          end
        else
          new_addons_settings.delete(addon_name)
        end
      end
    end

    private

    def check_boolean(value)
      unless %w[0 1].include?(value.to_s)
        raise Service::Kit::AttributeAssignmentError.new "#{value} is not a boolean."
      end
    end

    def cast_boolean(value)
      case value
      when '1'
        true
      when '0'
        false
      end
    end

    def check_number_inclusion(value, allowed_values)
      unless allowed_values.include?(value.to_f)
        raise Service::Kit::AttributeAssignmentError.new "#{value} is not included in #{allowed_values.inspect}."
      end
    end

    def check_string_inclusion(value, allowed_values)
      unless allowed_values.map(&:to_s).include?(value.to_s)
        raise Service::Kit::AttributeAssignmentError.new "#{value} is not included in #{allowed_values.inspect}."
      end
    end

  end

  class Kit
    class AttributeAssignmentError < Exception; end;
  end
end
