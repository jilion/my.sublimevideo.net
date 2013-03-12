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
          app_designs, addon_plans = {}, {}
          App::Design.custom.each do |design|
            app_designs[design.name] = design.id if rand >= 0.6
          end
          AddonPlan.where{ price > 0 }.each do |addon_plan|
            addon_plans[addon_plan.addon.name] = addon_plan.id if rand >= 0.6
          end
          options = rand >= 0.7 ? { force: 'sponsored' } : (rand >= 0.5 ? { force: 'subscribed' } : {})
          service.update_billable_items(app_designs, addon_plans, options)
        end
        if rand >= 0.5
          Timecop.return
          Timecop.travel(created_at + 30.days)
          TrialHandler.new(site).activate_billable_items_out_of_trial
        end
        Timecop.return
        puts "#{site.hostname} created for #{user.name}"
      end
    end
  end

end
