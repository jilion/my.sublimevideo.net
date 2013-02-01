module Service
  SettingsSanitizer = Struct.new(:kit, :settings) do

    def initialize(*args)
      super
      @sanitized_settings = Hash.new { |hash, key| hash[key] = {} }
    end

    def sanitize
      settings.each do |addon_name, new_addon_plan_settings|
        addon_plan = kit.site.addon_plan_for_addon_name(addon_name)

        sanitize_new_addon_plan_settings(addon_plan, new_addon_plan_settings)
      end

      @sanitized_settings
    end

    private

    def sanitize_new_addon_plan_settings(addon_plan, new_addon_plan_settings)
      return unless addon_plan_settings_template = addon_plan.settings_template_for(kit.design).try(:template)

      new_addon_plan_settings.each do |new_addon_setting_key, new_addon_setting_value|
        sanitize_new_addon_plan_setting(addon_plan, addon_plan_settings_template, new_addon_setting_key, new_addon_setting_value)
      end
    end

    def sanitize_new_addon_plan_setting(addon_plan, addon_plan_settings_template, setting_key, setting_value)
      addon_name = addon_plan.addon.name
      setting_key = setting_key.to_sym
      return unless addon_plan_setting_template = addon_plan_settings_template[setting_key]

      case addon_plan_setting_template[:type]
      when 'image', 'url'
        @sanitized_settings[addon_name][setting_key] = sanitize_url(setting_value)

      when 'float'
        range = (addon_plan_setting_template[:range][0]..addon_plan_setting_template[:range][1])
        @sanitized_settings[addon_name][setting_key] = sanitize_number(setting_value, range)

      when 'boolean'
        setting_value = cast_boolean(setting_value)

        unless value_is_allowed?(setting_value, addon_plan_setting_template[:values])
          setting_value = addon_plan_setting_template[:default]
        end
        @sanitized_settings[addon_name][setting_key] = setting_value

      when 'string'
        if addon_plan_setting_template[:values].nil? || value_is_allowed?(setting_value, addon_plan_setting_template[:values])
          @sanitized_settings[addon_name][setting_key] = setting_value
        end

      when 'array'
        @sanitized_settings[addon_name][setting_key] = keep_allowed_values(setting_value, addon_plan_setting_template[:item][:values])
      end
    end

    def cast_boolean(value)
      case value
      when '1'
        true
      when '0'
        false
      else
        value
      end
    end

    def sanitize_url(url)
      if !url.nil? && url != '' && url !~ %r{\A(https?:)?//}
        url = "http://#{url}"
      end

      url
    end

    def sanitize_number(value, allowed_values)
      unless allowed_values.include?(value.to_f)
        value = (allowed_values.max - allowed_values.min) / 2
      end

      value.to_f.round(2)
    end

    def value_is_allowed?(value, allowed_values)
      allowed_values.include?(value)
    end

    def keep_allowed_values(values, allowed_values)
      values = string_to_array(values) if values.is_a?(String)
      values & allowed_values
    end

    def string_to_array(string)
      string.split(/[\s,]+/)
    end

  end
end
