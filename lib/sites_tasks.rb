module SitesTasks
  def self.regenerate_templates(options = {})
    Site.where(token: SiteToken.tokens).pluck(:id).each do |site_id|
      LoaderGenerator.delay(queue: 'my').update_all_stages!(site_id) if options[:loaders]
      SettingsGenerator.delay(queue: 'my').update_all!(site_id) if options[:settings]
    end
    puts 'Important sites scheduled...' unless Rails.env.test?

    scheduled = 0
    Site.active.order(last_30_days_admin_starts: :desc).pluck(:id).each do |site_id|
      LoaderGenerator.delay(queue: 'my-loader').update_all_stages!(site_id) if options[:loaders]
      SettingsGenerator.delay(queue: 'my-low').update_all!(site_id) if options[:settings]

      scheduled += 1
      puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
    end

    "Schedule finished: #{scheduled} sites will have their loader and license re-generated"
  end

  def self.subscribe_all_sites_to_best_addon_plans
    subscriptions = {}
    subscriptions[:logo] = AddonPlan.get('logo', 'custom').id
    subscriptions[:social_sharing] = AddonPlan.get('social_sharing', 'standard').id
    subscriptions[:embed] = AddonPlan.get('embed', 'auto').id
    subscriptions[:cuezones] = AddonPlan.get('cuezones', 'standard').id
    subscriptions[:google_analytics] = AddonPlan.get('google_analytics', 'standard').id
    subscriptions[:support] = AddonPlan.get('support', 'standard').id # downgrade everyone to no support

    scheduled = 0
    Site.active.find_each do |site|
      SiteManager.delay(queue: 'my').update_billable_items(site.id, {}, subscriptions, force: 'sponsored')
      scheduled += 1
      puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
    end

    "Schedule finished: #{scheduled} sites will be subscribed to the best add-ons"
  end

  def self.exit_beta
    # 1. Exit beta for all designs & addon plans by setting required_stage to 'stable' and settings stable_at.
    beta_designs = Design.where(stable_at: nil)
    beta_addon_plans = AddonPlan.where(stable_at: nil)
    beta_designs.update_all(stable_at: Time.now.utc, required_stage: 'stable')
    beta_addon_plans.update_all(stable_at: Time.now.utc, required_stage: 'stable')

    # 2. Delays SiteManager.update_billable_items for all non-archived sites
    scheduled = 0
    Site.not_archived.pluck(:id).each do |site_id|
      ExitBetaHandler.delay(queue: 'my').exit_beta(site_id)
      scheduled += 1
      puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
    end

    "Schedule finished: #{scheduled} sites will be moved out of beta"
  end
end
