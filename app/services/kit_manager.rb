class KitManager
  attr_reader :kit

  def initialize(kit)
    @kit = kit
  end

  def save(params)
    Kit.transaction do
      kit.name      = params[:name]
      kit.design_id = params[:design_id]
      kit.settings  = SettingsSanitizer.new(kit, params[:settings]).sanitize
      kit.save!
      kit.site.touch(:settings_updated_at)
    end
    SettingsGenerator.delay.update_all!(kit.site_id)
    Librato.increment 'kits.events', source: 'update'
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

end
