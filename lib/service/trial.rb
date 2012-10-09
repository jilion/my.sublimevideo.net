require_dependency 'service/site'

module Service
  class Trial

    class << self

      def activate_billable_items_out_of_trial!
        ::Site.not_archived.select('DISTINCT("sites".*)').joins(:billable_items).where { billable_items.state == 'trial' }.each do |site|
          if site.billable_items.where(state: 'trial').any? { |billable_item| site.out_of_trial?(billable_item.item) }
            delay.activate_billable_items_out_of_trial_for_site!(site.id)
          end
        end
      end

      def activate_billable_items_out_of_trial_for_site!(site_id)
        site = ::Site.not_archived.find(site_id)

        activated_app_designs = site.billable_items.app_designs.where(state: 'trial').inject({}) do |hash, billable_item|
          if site.out_of_trial?(billable_item.item)
            hash[billable_item.item.name] = site.user.cc? ? billable_item.item.id : '0'
          end
          hash
        end

        activated_addon_plans = site.billable_items.addon_plans.where(state: 'trial').inject({}) do |hash, billable_item|
          if site.out_of_trial?(billable_item.item)
            hash[billable_item.item.addon.name] = (site.user.cc? ? billable_item.item : billable_item.item.addon.free_plan).id
          end
          hash
        end

        Service::Site.new(site).update_billable_items!(activated_app_designs, activated_addon_plans)
      end

    end

  end
end
