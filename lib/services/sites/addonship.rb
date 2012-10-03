require_dependency 'services/sites'

Services::Sites::Addonship = Struct.new(:site) do
  class << self

    def activate_addonships_out_of_trial!
      Site.with_out_of_trial_addons.find_each(batch_size: 100) do |site|
        delay.activate_addonships_out_of_trial_for_site!(site.id)
      end
    end

    def activate_addonships_out_of_trial_for_site!(site_id)
      site = Site.find(site_id)

      Addons::Addon.transaction do
        site.addons.out_of_trial.each do |addon|
          new(site).activate_addonship!(addon)
        end
      end
    end

  end

  # new_addonships => { 'category1' => 'name', 'category2' => '0' }
  def update_addonships!(new_addonships)
    Addons::Addon.transaction do
      new_addonships.each do |category, addon_name_to_activate|
        addon_to_activate = nil
        if addon_name_to_activate != '0'
          addon_to_activate = Addons::Addon.get(category.to_s, addon_name_to_activate)

          activate_addonship!(addon_to_activate)
        end
        deactivate_addonships_in_category!(category, addon_to_activate)
      end
    end
  end

  def activate_addonship!(addon)
    return if site.addon_is_active?(addon)

    addonship = addonship_from_addon(addon)

    if addon.beta?
      addonship.start_beta!
    else
      addonship_out_of_trial?(addonship) || free_addon?(addon) ? addonship.subscribe! : addonship.start_trial!
    end
  end

  def deactivate_addonships_in_category!(*args)
    addonships_in_category(*args).each do |addonship|
      addonship.cancel! if site.addon_is_active?(addonship.addon)
    end
  end

  private

  def addonship_out_of_trial?(addonship, trial_start_date = BusinessModel.days_for_trial.days.ago)
    !addonship.trial_started_on.nil? && addonship.trial_started_on < trial_start_date
  end

  def free_addon?(addon)
    addon.price.zero?
  end

  def addonships_in_category(category, except_addon = nil)
    site.addonships.in_category(category.to_s).except_addon_ids(except_addon.nil? ? [] : except_addon.id)
  end

  def addonship_from_addon(addon)
    site.addonships.find_or_initialize_by_addon_id(addon.id)
  end

end
