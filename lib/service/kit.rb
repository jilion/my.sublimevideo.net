require_dependency 'service/settings_sanitizer'

module Service
  Kit = Struct.new(:kit) do

    def save(params)
      creation = kit.site.new_record?
      ::Kit.transaction do
        kit.name          = params.delete(:name)
        kit.app_design_id = params.delete(:app_design_id)
        kit.settings      = Service::SettingsSanitizer.new(kit, params.delete(:addons)).sanitize
        kit.save!
        kit.site.touch(:settings_updated_at)
      end
      Service::Settings.delay.update_all_types!(kit.site_id)
      Librato.increment 'kits.events', source: creation ? 'create' : 'update'
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

  end
end
