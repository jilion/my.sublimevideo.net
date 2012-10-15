module Service
  Kit = Struct.new(:kit) do

    # app_designs => { "classic"=>"0", "light"=>"42" }
    # addon_plans => { "logo"=>"80", "support"=>"88" }
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
          Rails.logger.info setting_template.inspect
          Rails.logger.info new_addon_setting_key
          case setting_template[:values]
          when 'float_0_1'
            new_addons_settings[addon_id][new_addon_setting_key] = new_addon_setting_value.to_f.round(2)
          end
        end
      end
    end

  end
end
