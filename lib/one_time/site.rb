module OneTime
  module Site

    class << self

      def regenerate_templates(options = {})
        scheduled = 0
        ::Site.active.find_each(batch_size: 100) do |site|
          if options[:loaders]
            ::Service::Loader.delay(queue: 'low').update_all_stages!(site.id, purge: false)
          end
          if options[:settings]
            ::Service::Settings.delay(queue: 'low').update_all_types!(site.id, purge: false)
          end

          scheduled += 1

          if (scheduled % 500).zero?
            puts "#{scheduled} sites scheduled..."
          end
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
        ::Site.not_archived.find_each(batch_size: 100) do |site|
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
        ::Site.not_archived.includes(:kits).where(kits: { id: nil }).find_each(batch_size: 100) do |site|
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
        result = []
        if site = ::Site.find_by_token(SiteToken[:my])
          site.default_kit.update_column(:name, 'Classic')

          PreviewKit.kit_ids.each do |design_name, kit_identifier|
            next if design_name == 'classic'

            site.kits.create!({ name: I18n.t("app_designs.#{design_name}"), app_design_id: App::Design.get(design_name).id }, as: :admin)
            result << I18n.t("app_designs.#{design_name}")
          end
        end
        'Created preview kits: ' + result.join(', ') + ' for my.sublimevideo.net'
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
