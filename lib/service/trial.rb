require_dependency 'service/site'

module Service
  class Trial

    class << self

      def send_trial_will_expire_email
        BusinessModel.days_before_trial_end.each do |days_before_trial_end|
          ::Site.select('DISTINCT("sites".*)').not_archived.joins(:billable_items)
          .where { billable_items.state == 'trial' }.find_each(batch_size: 100) do |site|
            site.billable_items.select { |bi| site.out_of_trial_on?(bi.item, days_before_trial_end.days.from_now) }.each do |billable_item|
              BillingMailer.delay.trial_will_expire(billable_item.id)
            end
          end
        end
      end

      def activate_billable_items_out_of_trial!
        ::Site.select('DISTINCT("sites".*)').not_archived.joins(:billable_items)
        .where { billable_items.state == 'trial' }.find_each(batch_size: 100) do |site|
          if site.billable_items.where(state: 'trial').any? { |bi| site.out_of_trial?(bi.item) }
            delay.activate_billable_items_out_of_trial_for_site!(site.id)
          end
        end
      end

      def activate_billable_items_out_of_trial_for_site!(site_id)
        site = ::Site.not_archived.find(site_id)

        activated_app_designs = site.billable_items.app_designs.where(state: 'trial').inject({}) do |hash, billable_item|
          if site.out_of_trial?(billable_item.item)
            hash[billable_item.item.name] = if site.user.cc?
              billable_item.item.id
            else
              BillingMailer.delay.trial_has_expired(site.id, billable_item.item.class.to_s, billable_item.item.id)
              '0'
            end
          end
          hash
        end

        activated_addon_plans = site.billable_items.addon_plans.where(state: 'trial').inject({}) do |hash, billable_item|
          if site.out_of_trial?(billable_item.item)
            hash[billable_item.item.addon.name] = if site.user.cc?
              billable_item.item.id
            else
              BillingMailer.delay.trial_has_expired(site.id, billable_item.item.class.to_s, billable_item.item.id)
              billable_item.item.addon.free_plan.id
            end
          end
          hash
        end

        Service::Site.new(site).update_billable_items!(activated_app_designs, activated_addon_plans)
      end

    end

  end
end
