class SitesPopulator < Populator

  BASE_SITES = %w[vimeo.com dribbble.com jilion.com swisslegacy.com maxvoltar.com 37signals.com mattrunks.com zeldman.com devour.com deaxon.com veerle.duoh.com]

  def execute
    PopulateHelpers.empty_tables(Site)

    User.all.each do |user|
      BASE_SITES.sample(3).each do |hostname|
        created_at = rand(24).months.ago
        Timecop.travel(created_at)
        site = user.sites.build(hostname: hostname)
        service = SiteManager.new(site).tap { |s| s.create }
        if rand >= 0.3
          designs, addon_plans = {}, {}
          Design.custom.each do |design|
            designs[design.name] = design.id if rand >= 0.6
          end
          AddonPlan.where("price > ?", 0).each do |addon_plan|
            addon_plans[addon_plan.addon_name] = addon_plan.id if rand >= 0.6
          end
          options = rand >= 0.7 ? { force: 'sponsored' } : (rand >= 0.5 ? { force: 'subscribed' } : {})
          service.update_billable_items(designs, addon_plans, options)
        end
        if rand >= 0.5
          Timecop.return
          Timecop.travel(created_at + 30.days)
          TrialHandler.new(site).activate_billable_items_out_of_trial
        end
        Timecop.return
        puts "#{site.hostname} created for #{user.name}"
      end

      url = 'https://my.sublimevideo.net/private_api/sites.json?select[]=token&with_addon_plan=stats-realtime&by_last_30_days_billable_video_views=desc'
      sites = JSON[`curl -g -H 'Authorization: Token FJUs29vEt28GaRTrJh8mzeH8yQJM3TUZ' #{url}`]
      realtime_stats_addon_plan = AddonPlan.get('stats', 'realtime')

      sites.each do |site|
        puts "Create site #{site['hostname']} [#{site['token']}] with the real-time stats add-on"
        site = user.sites.build(hostname: site['hostname'])
        service = SiteManager.new(site).tap { |s| s.create; s.update_column(:token, site['token']) }
        service.update_billable_items({}, { 'stats' => realtime_stats_addon_plan.id }, { force: 'sponsored' })
      end
    end

    sv_site = User.first.sites.first
    sv_site.update_attributes(token: SiteToken[:www], hostname: 'sublimevideo.net')
    SiteManager.new(sv_site).update_billable_items({}, { stats: AddonPlan.get('stats', 'realtime').id }, { force: 'subscribed' })
  end

end
