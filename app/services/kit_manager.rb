class KitManager
  attr_reader :kit

  def initialize(kit)
    @kit = kit
  end

  def save(params)
    creation = kit.site.new_record?
    Kit.transaction do
      kit.name          = params.delete(:name)
      kit.app_design_id = params.delete(:app_design_id)
      kit.settings      = SettingsSanitizer.new(kit, params.delete(:settings)).sanitize
      kit.save!
      kit.site.touch(:settings_updated_at)
    end
    SettingsGenerator.delay.update_all!(kit.site_id)
    Librato.increment 'kits.events', source: creation ? 'create' : 'update'
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

end
