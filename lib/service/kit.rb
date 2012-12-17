require_dependency 'service/settings_sanitizer'

module Service
  Kit = Struct.new(:kit) do

    def create(params)
      ::Kit.transaction do
        kit.settings      = Service::SettingsSanitizer.new(kit, params.delete(:addons)).sanitize
        kit.save!

        kit.site.touch(:settings_updated_at)
        Service::Settings.delay.update_all_types!(kit.site_id)
      end
      Librato.increment 'kits.events', source: 'create'
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
      Librato.increment 'kits.events', source: 'update'
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

  end
end
