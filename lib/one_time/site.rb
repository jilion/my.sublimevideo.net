module OneTime
  module Site

    class << self

      def regenerate_templates(options = {})
        ::Site.select(:id).where(token: ::SiteToken.tokens).each do |site|
          ::Service::Loader.delay(queue: 'high').update_all_stages!(site.id, purge: true) if options[:loaders]
          ::Service::Settings.delay(queue: 'high').update_all_types!(site.id, purge: true) if options[:settings]
        end
        puts "Important sites scheduled..."

        scheduled = 0
        ::Site.active.select(:id).order{ last_30_days_main_video_views.desc }.find_each do |site|
          ::Service::Loader.delay(queue: 'loader').update_all_stages!(site.id, purge: false) if options[:loaders]
          ::Service::Settings.delay(queue: 'low').update_all_types!(site.id, purge: false) if options[:settings]

          scheduled += 1
          puts "#{scheduled} sites scheduled..." if (scheduled % 1000).zero?
        end

        "Schedule finished: #{scheduled} sites will have their loader and license re-generated"
      end

      # TODO: Remove after launch
      def move_staging_hostnames_from_extra
        ::Site.not_archived.where{ extra_hostnames =~ '%staging%' }.each do |site|
          extra, staging = [], []
          site.extra_hostnames.split(/,\s*/).each do |hostname|
            if hostname =~ /staging/
              staging << hostname
            else
              extra << hostname
            end
          end
          site.update_attributes(extra_hostnames: extra.join(','), staging_hostnames: staging.join(','))
        end
      end

      # TODO: Remove after launch
      def add_already_paid_amount_to_balance_for_monthly_plans
        processed, total = 0, 0
        ::Site.transaction do
          ::Site.not_archived.where{ plan_id >> Plan.where(name: %w[plus premium], cycle: 'month').map(&:id) }.find_each(batch_size: 100) do |site|
            price_per_day = (site.plan.price * 12) / 365
            add_to_balance = [0, ((site.plan_cycle_ended_at + 1.second - Time.now.utc) / 1.day).floor * price_per_day].max
            old_balance = site.user.balance
            site.user.increment!(:balance, add_to_balance)

            unless Rails.env.test?
              puts "#{((site.plan_cycle_ended_at + 1.second - Time.now.utc) / 1.day).floor} days left " +
                   "until #{site.plan_cycle_ended_at + 1.second} (price per day: $#{price_per_day.to_f / 100}), added to " +
                   "balance: #{add_to_balance.to_f / 100}. Old balance: $#{old_balance.to_f / 100}, " +
                   "new balance: $#{site.user.balance.to_f / 100}"
            end

            processed += 1
            total += add_to_balance
          end
        end

        "Finished: $#{total.to_f / 100} was added to user balances (for #{processed} sites in monthly plans)."
      end

      # TODO: Remove after launch
      def migrate_yearly_plans_to_monthly_plans
        processed, total = 0, 0
        ::Site.transaction do
          ::Site.not_archived.where{ plan_id >> Plan.where(name: %w[plus premium], cycle: 'year').map(&:id) }.find_each(batch_size: 100) do |site|
            new_plan = Plan.where(name: site.plan.name, cycle: 'month').first
            site.update_column(:plan_id, new_plan.id)

            price_per_day  = (new_plan.price * 12) / 365
            add_to_balance = [0, ((site.plan_cycle_ended_at + 1.second - Time.now.utc) / 1.day).floor * price_per_day].max
            site.user.increment!(:balance, add_to_balance)

            processed += 1
            total += add_to_balance
          end
        end

        "Finished: #{processed} sites were migrated to monthly plans and $#{total.to_f / 100} was added to user balances."
      end

      # TODO: Remove after launch
      def migrate_plans_to_addons
        scheduled = 0
        free_addon_plans          = AddonPlan.free_addon_plans
        free_addon_plans_filtered = AddonPlan.free_addon_plans(reject: %w[logo stats support])
        ::Site.select(:id).not_archived.find_each do |site|
          Service::Site.delay(queue: 'low').migrate_plan_to_addons!(site.id, free_addon_plans, free_addon_plans_filtered)

          scheduled += 1
          if (scheduled % 500).zero?
            puts "#{scheduled} sites scheduled..."
          end
        end

        "Schedule finished: #{scheduled} sites were migrated to the add-ons business model (there are now #{BillableItem.count} billable items in the DB)."
      end

      # TODO: Remove after launch
      def create_default_kit_for_all_non_archived_sites
        scheduled = 0
        ::Site.select(:id).not_archived.includes(:kits).where(kits: { id: nil }).find_each do |site|
          Service::Site.delay(queue: 'low').create_default_kit(site.id)

          scheduled += 1
          if (scheduled % 500).zero?
            puts "#{scheduled} sites scheduled..."
          end
        end

        "Schedule finished: #{scheduled} sites had a default kit created."
      end

      # TODO: Remove after launch
      def create_preview_kits
        text = ''
        [:www, :my, :test, 's96w44sn'].each do |subdomain_or_token|
          result = []
          if site = ::Site.find_by_token(subdomain_or_token.is_a?(Symbol) ? SiteToken[subdomain_or_token] : subdomain_or_token)
            site.default_kit.update_column(:name, 'Classic')
            site.update_column(:extra_hostnames, 't.sublimevideo.net') if subdomain_or_token == 's96w44sn'

            designs_to_sponsor = App::Design.custom.inject({}) do |memo, design|
              case subdomain_or_token
              when :test
                memo[design.name] = design.id unless design.name == 'df'
              when Symbol
                memo[design.name] = design.id unless design.name.in?(%w[blizzard df])
              when 's96w44sn' # DF
                memo[design.name] = design.id if design.name == 'df'
              end
              memo
            end

            addon_plans_to_sponsor = if subdomain_or_token == 's96w44sn' # DF
              { 'logo' => AddonPlan.get('logo', 'disabled').id }
            else
              AddonPlan.includes(:addon).custom.inject({}) do |memo, addon_plan|
                memo[addon_plan.addon.name] = addon_plan.id unless subdomain_or_token == 's96w44sn'
                memo
              end
            end
            Service::Site.new(site).update_billable_items(designs_to_sponsor, addon_plans_to_sponsor, allow_custom: true, force: 'sponsored')

            PreviewKit.kit_names.each do |design_name|
              next if design_name == 'classic'

              create_kit = case subdomain_or_token
              when :test
                design_name != 'df'
              when Symbol
                !design_name.in?(%w[blizzard df])
              when 's96w44sn' # DF
                design_name == 'df'
              end

              if create_kit
                design = App::Design.get(design_name)
                site.kits.create!({ name: I18n.t("app_designs.#{design_name}"), app_design_id: design.id }, as: :admin)
                result << I18n.t("app_designs.#{design_name}")
              end
            end
          end
          text += "Created preview kits: ' + #{result.join(', ')} + ' for {'www','my','test'}.sublimevideo.net\n"
        end

        text
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

      def update_accessible_stage
        processed = ::Site.not_archived.where(accessible_stage: 'stable').update_all(accessible_stage: 'beta')
        processed = ::Site.not_archived.where(accessible_stage: 'dev').update_all(accessible_stage: 'alpha')

        "Finished: #{processed} sites were updated."
      end

    end

  end
end
