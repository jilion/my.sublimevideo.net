module OneTime
  module Site

    class << self

      def regenerate_templates(options = {})
        scheduled, delay = 0, 5
        ::Site.active.find_each(batch_size: 100) do |site|
          if options[:loaders]
            ::Service::Loader.delay(priority: 200, run_at: delay.seconds.from_now).update_all_stages!(site.id, touch: false, purge: false)
          end
          if options[:settings]
            ::Service::Settings.delay(priority: 200, run_at: delay.seconds.from_now).update_all_types!(site.id, touch: false, purge: false)
          end

          scheduled += 1

          if (scheduled % 500).zero?
            puts "#{scheduled} sites scheduled..."
            delay += 5
          end
        end

        "Finished: #{scheduled} sites will have their loader and license re-generated"
      end

      def add_already_paid_amount_to_balance_for_monthly_plans
        processed, total = 0, 0
        ::Site.transaction do
          ::Site.not_archived.where{ plan_id >> Plan.where(name: %w[plus premium], cycle: 'month').map(&:id) }.find_each(batch_size: 100) do |site|
            price_per_day = (site.plan.price * 12) / 365
            add_to_balance = [0, ((site.plan_cycle_ended_at + 1.second - Time.now.utc) / 1.day).floor * price_per_day].max
            site.user.increment!(:balance, add_to_balance)

            processed += 1
            total += add_to_balance
          end
        end

        "Finished: $#{total} was added to user balances (for #{processed} sites in monthly plans)."
      end

      def migrate_yearly_plans_to_monthly_plans
        processed, total = 0, 0
        ::Site.transaction do
          ::Site.not_archived.where{ plan_id >> Plan.where(name: %w[plus premium], cycle: 'year').map(&:id) }.find_each(batch_size: 100) do |site|
            new_plan = Plan.where(name: site.plan.name, cycle: 'month').first
            site.update_column(:plan_id, new_plan.id)

            price_per_day = (new_plan.price * 12) / 365
            add_to_balance = [0, ((site.plan_cycle_ended_at + 1.second - Time.now.utc) / 1.day).floor * price_per_day].max
            site.user.increment!(:balance, add_to_balance)

            processed += 1
            total += add_to_balance
          end
        end

        "Finished: #{processed} sites were migrated to monthly plans and $#{total} was added to user balances."
      end

      def migrate_plans_to_addons
        processed = 0
        ::Site.transaction do
          ::Site.not_archived.find_each(batch_size: 100) do |site|
            Service::Site.new(site).migrate_plan_to_addons!

            processed += 1
          end
        end

        "Finished: #{processed} sites were migrated to the add-ons business model (there are now #{BillableItem.count} billable items in the DB)."
      end

      def create_default_kit_for_all_non_archived_sites
        processed = 0
        ::Site.transaction do
          ::Site.not_archived.find_each(batch_size: 100) do |site|
            Service::Site.new(site).send :create_default_kit

            processed += 1
          end
        end

        "Finished: #{processed} sites had a default kit created."
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
