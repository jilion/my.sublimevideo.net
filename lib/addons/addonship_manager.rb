module Addons
  class AddonshipManager < Struct.new(:site, :addon)

    def self.update_addonships_for_site!(site, new_addonships)
      Addons::Addon.transaction do
        new_addonships.each do |category, addon_name|
          if addon_name == '0'
            new(site).deactivate_addonships_in_category!(category)
          else
            manager = new(site, Addons::Addon.find_by_category_and_name(category.to_s, addon_name.to_s))
            manager.activate!
          end
        end
      end
    end

    def initialize(*args)
      super
      @addonships_in_category = {}
    end

    def activate!
      return if site.addon_is_active?(addon)

      deactivate_addonships_in_category!(addon.category, except_addon_id: addon.id)
      activate_addonship
    end

    def deactivate_addonships_in_category!(category, options = {})
      addonships_in_category(category, options[:except_addon_id]).each do |addonship|
        addonship.cancel!
      end
    end

    def out_of_trial?(oldest_trial_start_date = BusinessModel.days_for_trial.days.ago)
      !addonship.trial_started_on.nil? && addonship.trial_started_on < oldest_trial_start_date
    end

    def free_addon?
      addon.price.zero?
    end

    private

    def activate_addonship
      addonship.state = if addon.beta?
        'beta'
      else
        out_of_trial? || free_addon? ? 'paying' : 'trial'
      end
      addonship.save!
    end

    def addonships_in_category(category, except_addon_id = nil)
      key = "#{category}_except_#{except_addon_id}"
      @addonships_in_category[key] ||= site.addonships.in_category(category).except_addon_id(except_addon_id)
    end

    def addonship
      @addonship ||= site.addonships.find_or_initialize_by_addon_id(addon.id)
    end

  end
end
