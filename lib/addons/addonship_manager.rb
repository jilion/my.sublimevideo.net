module Addons
  class AddonshipManager < Struct.new(:site, :addon)

    def initialize(*args)
      super
      @addonships_in_category = {}
    end

    def activate!
      return if active?

      deactivate_addonships_in_category!(addon.category, except_addon_id: addon.id)
      activate_addonship!
    end

    def deactivate_addonships_in_category!(category, options = {})
      addonships_in_category(category, options[:except_addon_id]).each do |addonship|
        addonship.cancel!
      end
    end

    def active?
      site.addon_is_active?(addon)
    end

    def out_of_trial?(trial_start_date = BusinessModel.days_for_trial.days.ago)
      !addonship.trial_started_on.nil? && addonship.trial_started_on < trial_start_date
    end

    def free?
      addon.price.zero?
    end

    private

    def activate_addonship!
      if addon.beta?
        addonship.start_beta!
      else
        out_of_trial? || free? ? addonship.subscribe! : addonship.start_trial!
      end
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
