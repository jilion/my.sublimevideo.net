module OneTime
  module Site

    class << self

      def regenerate_templates(options = {})
        ::Site.select(:id).where(token: ::SiteToken.tokens).each do |site|
          ::LoaderGenerator.delay(queue: 'high').update_all_stages!(site.id) if options[:loaders]
          ::SettingsGenerator.delay(queue: 'high').update_all_types!(site.id) if options[:settings]
        end
        puts "Important sites scheduled..."

        scheduled = 0
        ::Site.active.select(:id).order{ last_30_days_main_video_views.desc }.find_each do |site|
          ::LoaderGenerator.delay(queue: 'loader').update_all_stages!(site.id) if options[:loaders]
          ::SettingsGenerator.delay(queue: 'low').update_all_types!(site.id) if options[:settings]

          scheduled += 1
          puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
        end

        "Schedule finished: #{scheduled} sites will have their loader and license re-generated"
      end

      def subscribe_all_sites_to_embed_addon
        embed_addon = AddonPlan.get('embed', 'standard')
        scheduled = 0
        ::Site.active.find_each do |site|
          next if site.addon_plans.where { billable_items.item_type == 'AddonPlan' }.where { billable_items.item_id == embed_addon }.exists?

          SiteManager.delay(queue: 'one_time').subscribe_site_to_embed_addon(site.id, embed_addon.id)
          scheduled += 1
          puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
        end

        "Schedule finished: #{scheduled} sites will be subscribed to the embed add-on"
      end

      def without_versioning
        was_enabled = PaperTrail.enabled?
        PaperTrail.enabled = false
        begin
          yield
        ensure
          PaperTrail.enabled = was_enabled
        end
      end

    end

  end
end
