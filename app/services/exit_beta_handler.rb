class ExitBetaHandler
  attr_reader :site

  def self.exit_beta(site_id)
    new(::Site.find(site_id)).exit_beta
  end

  def initialize(site)
    @site = site
  end

  def exit_beta
    designs = site.billable_items.app_designs.beta.inject({}) do |hash, billable_item|
      hash[billable_item.item.name] = billable_item.item.id
      hash
    end
    addon_plans = site.billable_items.addon_plans.beta.inject({}) do |hash, billable_item|
      hash[billable_item.item.addon.name] = if !site.out_of_trial?(billable_item.item) || site.user.cc?
        billable_item.item.id
      else
        if free_plan = billable_item.item.addon.free_plan
          free_plan.id
        else
          '0'
        end
      end
      hash
    end
    SiteManager.delay(queue: 'one_time').update_billable_items(site.id, designs, addon_plans)
  end

end
