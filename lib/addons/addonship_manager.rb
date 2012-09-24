module Addons
  class AddonshipManager

    def initialize(site, addon_class = Addons::Addon)
      @site        = site
      @addon_class = addon_class
    end

    def update_addonships!(new_addonships)
      @addon_class.transaction do
        new_addonships.each do |category, addon_name|
          if addon_name == '0'
            deactivate_addons_in_category!(category)
          else
            activate_addon!(@addon_class.find_by_category_and_name(category.to_s, addon_name.to_s))
          end
        end
      end
    end

    def activate_addon!(addon)
      return if @site.addon_is_active?(addon)


      deactivate_addonships_in_category(addon.category, except_addon_id: addon.id)
      activate_addonship(addon)
    end

    def deactivate_addons_in_category!(category)
      deactivate_addonships_in_category(category)
    end

    private

    def deactivate_addonships_in_category(category, options = {})
      @site.addonships.in_category(category).except_addon_id(options[:except_addon_id]).each do |addonship|
        addonship.cancel!
      end
    end

    def activate_addonship(addon)
      addonship = @site.addonships.find_or_initialize_by_addon_id(addon.id)
      addonship.state = if addon.beta?
        'beta'
      else
        addonship.out_of_trial? || addon.price.zero? ? 'paying' : 'trial'
      end
      addonship.save!
    end

  end
end
