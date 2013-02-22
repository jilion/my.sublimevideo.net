class TrialHandler
  def self.send_trial_will_expire_email
    BusinessModel.days_before_trial_end.each do |days_before_trial_end|
      Site.select('DISTINCT("sites".*)').not_archived.joins(:billable_items)
      .where { billable_items.state == 'trial' }.find_each(batch_size: 100) do |site|
        site.billable_items.select { |bi| site.trial_ends_on?(bi.item, days_before_trial_end.days.from_now) }.each do |billable_item|
          BillingMailer.delay.trial_will_expire(billable_item.id)
        end
      end
    end
  end

  def self.activate_billable_items_out_of_trial!
    Site.select('DISTINCT("sites".*)').not_archived.joins(:billable_items)
    .where { billable_items.state == 'trial' }.find_each(batch_size: 100) do |site|
      if site.billable_items.where(state: 'trial').any? { |bi| site.out_of_trial?(bi.item) }
        delay.activate_billable_items_out_of_trial_for_site!(site.id)
      end
    end
  end

  def self.activate_billable_items_out_of_trial_for_site!(site_id)
    site = Site.not_archived.find(site_id)
    emails = []

    activated_app_designs = site.billable_items.app_designs.where(state: 'trial').inject({}) do |hash, billable_item|
      if site.out_of_trial?(billable_item.item)
        hash[billable_item.item.name] = if site.user.cc?
          billable_item.item.id
        else
          emails << [billable_item.item.class.to_s, billable_item.item.id]
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
          emails << [billable_item.item.class.to_s, billable_item.item.id]
          if free_plan = billable_item.item.addon.free_plan
            free_plan.id
          else
            '0'
          end
        end
      end
      hash
    end

    SiteManager.new(site).update_billable_items(activated_app_designs, activated_addon_plans)

    emails.each do |email|
      BillingMailer.delay.trial_has_expired(site_id, email[0], email[1])
    end
  end
end