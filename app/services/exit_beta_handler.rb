class ExitBetaHandler
  attr_reader :site

  def self.exit_beta(site_id)
    new(::Site.find(site_id)).exit_beta
  end

  def initialize(site)
    @site = site
  end

  def exit_beta
    designs, addon_plans = {}, {}
    subscriptions, emails = { designs: {}, addon_plans: {} }, []

    site.billable_items.state('beta').each do |subscription|
      trial_handler = TrialHandler.new(site)

      key = subscription.item_type.demodulize.tableize.to_sym
      subscriptions[key][subscription.item_parent_name] = if subscription.free? || !trial_handler.out_of_trial?(subscription.item) || site.user.cc?
        subscription.item.id
      else
        emails << { item_class: subscription.item_type, item_id: subscription.item.id }
        if free_plan = subscription.item.free_plan
          free_plan.id
        else
          '0'
        end
      end
    end

    SiteManager.delay(queue: 'one_time').update_billable_items(site.id, subscriptions[:designs], subscriptions[:addon_plans])
  end

end
