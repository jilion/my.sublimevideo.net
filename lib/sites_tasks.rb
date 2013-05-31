module SitesTasks
  def self.regenerate_templates(options = {})
    Site.select(:id).where(token: SiteToken.tokens).each do |site|
      LoaderGenerator.delay(queue: 'high').update_all_stages!(site.id) if options[:loaders]
      SettingsGenerator.delay(queue: 'high').update_all!(site.id) if options[:settings]
    end
    puts 'Important sites scheduled...'

    scheduled = 0
    Site.active.select(:id).order { last_30_days_main_video_views.desc }.find_each do |site|
      LoaderGenerator.delay(queue: 'loader').update_all_stages!(site.id) if options[:loaders]
      SettingsGenerator.delay(queue: 'low').update_all!(site.id) if options[:settings]

      scheduled += 1
      puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
    end

    "Schedule finished: #{scheduled} sites will have their loader and license re-generated"
  end

  def self.subscribe_all_sites_to_free_addon(addon_name, addon_plan_name)
    addon_plan = AddonPlan.get(addon_name, addon_plan_name)
    scheduled = 0
    Site.active.find_each do |site|
      next if site.addon_plans.where { billable_items.item_type == 'AddonPlan' }.where { billable_items.item_id == addon_plan }.exists?

      SiteManager.delay(queue: 'one_time').subscribe_site_to_addon(site.id, addon_name, addon_plan.id)
      scheduled += 1
      puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
    end

    "Schedule finished: #{scheduled} sites will be subscribed to the #{addon_name}-#{addon_plan_name} add-on"
  end

  def self.exit_beta
    # 1. Exit beta for all designs & addon plans by setting required_stage to 'stable' and settings stable_at.
    beta_designs = Design.where(stable_at: nil)
    beta_addon_plans = AddonPlan.where(stable_at: nil)
    beta_designs.update_all(stable_at: Time.now.utc, required_stage: 'stable')
    beta_addon_plans.update_all(stable_at: Time.now.utc, required_stage: 'stable')

    # 2. Delays SiteManager.update_billable_items for all non-archived sites
    scheduled = 0
    Site.not_archived.select(:id).find_each do |site|
      ExitBetaHandler.delay(queue: 'one_time').exit_beta(site.id)
      scheduled += 1
      puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
    end

    "Schedule finished: #{scheduled} sites will be moved out of beta"
  end
end
