require_dependency 'addons/addonship_manager'

module Addons
  class AddonshipsManager

    class << self

      def update_addonships_for_site!(site, new_addonships)
        Addons::Addon.transaction do
          new_addonships.each do |category, addon_name|
            if addon_name == '0'
              Addons::AddonshipManager.new(site).deactivate_addonships_in_category!(category)
            else
              manager = Addons::AddonshipManager.new(site, Addons::Addon.find_by_category_and_name(category.to_s, addon_name.to_s))
              manager.activate!
            end
          end
        end
      end

      def activate_addonships_out_of_trial!
        Site.with_out_of_trial_addons.find_each(batch_size: 100) do |site|
          delay.activate_addonships_out_of_trial_for_site!(site.id)
        end
      end

      def activate_addonships_out_of_trial_for_site!(site_id)
        site = Site.find(site_id)

        Addons::Addon.transaction do
          site.addons.out_of_trial.each do |addon|
            Addons::AddonshipManager.new(site, addon).activate!
          end
        end
      end

    end

  end
end
