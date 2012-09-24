module SiteModules::Addon
  extend ActiveSupport::Concern

  def addon_is_active?(addon)
    persisted? && addon.present? && addons.active.where{ id == addon.id }.exists?
  end

  def active_addon_in_category?(cat)
    persisted? && addons.active.where{ category == cat }.exists?
  end

end
