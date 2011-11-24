module OneTime
  module Site

    class << self

      def regenerate_all_loaders_and_licenses
        total = 0
        ::Site.active.find_each(batch_size: 100) do |site|
          ::Site.delay(priority: 200).update_loader_and_license(site.id, { loader: true, license: true })
          total += 1
        end

        "Finished: in total, #{total} sites will have their loader and license re-generated"
      end

      # Take all active sites that are (or has been) in a paid plan (and with no trial started date)
      # And set their trial started date to their first paid plan started date - <duration of trial>
      # So their "trial period" is already over.
      def set_trial_started_at_for_sites_created_before_v2
        without_versioning do
          total = 0
          ::Site.where { (first_paid_plan_started_at != nil) & (trial_started_at == nil) }.find_each(batch_size: 100) do |site|
            site.update_attribute(:trial_started_at, site.first_paid_plan_started_at - BusinessModel.days_for_trial.days)
            total += 1
          end

          "Finished: in total, #{total} sites were updated!"
        end
      end

      def current_sites_plans_migration
        without_versioning do
          total = 0

          # NOTE TO SELF:
          # We will have to handle sites with a pending plan
          legacy_plans = Plan.where { name >> (Plan::LEGACY_UNPAID_NAMES + Plan::LEGACY_STANDARD_NAMES) }.map(&:id)
          ::Site.active.where { (plan_id >> legacy_plans) | (pending_plan_id >> legacy_plans) }.find_each(batch_size: 100) do |site|
            add_to_balance = 0

            new_plan        = plan_switch(site.plan)
            next_cycle_plan = plan_switch(site.next_cycle_plan)

            if [planet_y_plan, galaxy_y_plan].include?(site.plan)
              new_discounted_price = if site.last_paid_invoice.plan_invoice_items.last.discounted_percentage.nil?
                new_plan.price
              else
                (new_plan.price * (1.0 - (site.last_paid_invoice.plan_invoice_items.last.discounted_percentage || 0)) / 100).to_i * 100
              end

              add_to_balance = site.last_paid_invoice.amount - (new_discounted_price * (1.0 + Vat.for_country(site.user.billing_country))).round
            end

            next_cycle_plan = nil if next_cycle_plan == new_plan

            # print "##{site.token} (##{site.id} #{site.hostname}): #{site.plan.title} (##{site.plan.id}) [next: #{site.next_cycle_plan.try(:title)} (##{site.next_cycle_plan_id})]"
            site.send(:write_attribute, :plan_id, new_plan.id)
            site.send(:write_attribute, :pending_plan_id, nil)
            site.send(:write_attribute, :next_cycle_plan_id, next_cycle_plan.try(:id))
            # print " => #{site.plan.title} (##{site.plan_id}) [next: #{site.next_cycle_plan.try(:title)} (##{site.next_cycle_plan_id})]"
            # puts " => #{site.reload.plan.title} (##{site.plan_id}) [next: #{site.next_cycle_plan.try(:title)} (##{site.next_cycle_plan_id})]"
            site.skip_pwd { site.save(validate: false) }
            total += 1

            unless add_to_balance.zero?
              site.user.increment!(:balance, add_to_balance)
              # puts "$#{add_to_balance/100.0} added to #{site.user.name}'s balance for ##{site.token} (##{site.id} #{site.hostname})!"
            end

            # puts

          end

          # Cancel all upgrade & failed invoices
          # USELESS, THERE IS NO UPGRADE & FAILED INVOICE
          # Invoice.failed.where { invoice_items_count > 1 }.map(&:cancel)

          # Update all renew & failed invoices
          Invoice.open_or_failed.where { renew == true }.find_each(batch_size: 100) do |invoice|
            new_plan = plan_switch(invoice.plan_invoice_items.last.item)
            last_plan_invoice_item = invoice.plan_invoice_items.last
            last_plan_invoice_item.item   = new_plan
            last_plan_invoice_item.price  = new_plan.price
            last_plan_invoice_item.amount = new_plan.price
            last_plan_invoice_item.save!

            invoice.set_invoice_items_amount
            invoice.set_vat_rate_and_amount
            invoice.set_balance_deduction_amount
            invoice.set_amount

            invoice.save!
          end

          "Finished: in total, #{total} sites were updated!"
        end
      end

      def plan_switch(old_plan)
        case old_plan
        when dev_plan
          free_plan
        when comet_m_plan, planet_m_plan
          plus_m_plan
        when comet_y_plan, planet_y_plan
          plus_y_plan
        when star_m_plan, galaxy_m_plan
          premium_m_plan
        when star_y_plan, galaxy_y_plan
          premium_y_plan
        else
          old_plan
        end
      end

      def dev_plan      ; ::Plan.where(name: 'dev').first; end
      def sponsored_plan; ::Plan.where(name: 'sponsored').first; end
      def comet_m_plan  ; ::Plan.where(name: 'comet', cycle: 'month').first; end
      def comet_y_plan  ; ::Plan.where(name: 'comet', cycle: 'year').first; end
      def planet_m_plan ; ::Plan.where(name: 'planet', cycle: 'month').first; end
      def planet_y_plan ; ::Plan.where(name: 'planet', cycle: 'year').first; end
      def star_m_plan   ; ::Plan.where(name: 'star', cycle: 'month').first; end
      def star_y_plan   ; ::Plan.where(name: 'star', cycle: 'year').first; end
      def galaxy_m_plan ; ::Plan.where(name: 'galaxy', cycle: 'month').first; end
      def galaxy_y_plan ; ::Plan.where(name: 'galaxy', cycle: 'year').first; end
      def custom_plan   ; ::Plan.where(name: 'custom - 1').first; end

      def free_plan     ; ::Plan.where(name: 'free').first; end
      def plus_m_plan ; ::Plan.where(name: 'plus', cycle: 'month').first; end
      def plus_y_plan ; ::Plan.where(name: 'plus', cycle: 'year').first; end
      def premium_m_plan   ; ::Plan.where(name: 'premium', cycle: 'month').first; end
      def premium_y_plan   ; ::Plan.where(name: 'premium', cycle: 'year').first; end

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
