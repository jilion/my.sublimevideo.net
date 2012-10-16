module Service
  Kit = Struct.new(:kit) do

    # params => { "<addon_id>" => { "settingKey" => "<value>" }
    def update_settings!(params)
      ::Kit.transaction do
        kit.app_design_id = params.delete(:app_design_id) if params[:app_design_id]

        update_addons_settings(params[:addons])

        kit.save!
      end
    end

    def update_addons_settings(new_addons_settings = {})
      kit.settings = sanitize_new_addons_settings(new_addons_settings)
    end

    def sanitize_new_addons_settings(new_addons_settings)
      new_addons_settings.each do |addon_id, new_addon_settings|
        addon_plan = kit.site.addon_plan_for_addon_id(addon_id)
        settings_template = addon_plan.settings_template_for(kit.design).template

        new_addon_settings.each do |new_addon_setting_key, new_addon_setting_value|
          setting_template = eval(settings_template[new_addon_setting_key])
          case setting_template[:type]
          when 'boolean'
            check_boolean(new_addon_setting_value)
          when 'float'
            new_addons_settings[addon_id][new_addon_setting_key] = new_addon_setting_value.to_f.round(2)
          when 'string'
            check_inclusion(new_addon_setting_value, setting_template[:values])
          end
        end
      end
    end

    private

    def check_boolean(value)
      raise Service::Kit::AttributeAssignmentError.new 'Is not a boolean.' unless %w[0 1].include?(value.to_s)
    end

    def check_inclusion(value, allowed_values)
      raise Service::Kit::AttributeAssignmentError.new 'Is not allowed.' unless allowed_values.map(&:to_s).include?(value.to_s)
    end

  end

  class Kit
    class AttributeAssignmentError < Exception; end;
  end
end
