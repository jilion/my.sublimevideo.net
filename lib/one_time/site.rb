module OneTime
  module Site

    class << self

      def regenerate_all_loaders_and_licenses
        total = 0
        ::Site.active.find_in_batches(batch_size: 100) do |sites|
          sites.each do |site|
            ::Site.delay(priority: 200).update_loader_and_license(site.id, { loader: true, license: true })
          end
          total += sites.count
        end
        "Finished: in total, #{total} sites will have their loader and license re-generated"
      end

      def set_trial_started_at_for_sites_created_before_v2
        total = 0
        ::Site.where { (first_paid_plan_started_at != nil) & (trial_started_at == nil) }.find_in_batches(batch_size: 100) do |sites|
          sites.each do |site|
            site.update_attribute(:trial_started_at, site.first_paid_plan_started_at - BusinessModel.days_for_trial.days)
            total += 1
          end
          puts "500 more..." if total % 500 == 0
        end
        "Finished: in total, #{total} sites were updated!"
      end

      def current_sites_plans_migration
        total = 0
        dev_plan       = Plan.where(name: 'dev').first
        sponsored_plan = Plan.where(name: 'sponsored').first
        comet_m_plan   = Plan.where(name: 'comet', cycle: 'month').first
        comet_y_plan   = Plan.where(name: 'comet', cycle: 'year').first
        planet_m_plan  = Plan.where(name: 'planet', cycle: 'month').first
        planet_y_plan  = Plan.where(name: 'planet', cycle: 'year').first
        star_m_plan    = Plan.where(name: 'star', cycle: 'month').first
        star_y_plan    = Plan.where(name: 'star', cycle: 'year').first
        galaxy_m_plan  = Plan.where(name: 'galaxy', cycle: 'month').first
        galaxy_y_plan  = Plan.where(name: 'galaxy', cycle: 'year').first
        custom_plan    = Plan.where(name: 'custom1').first
        
        free_plan     = Plan.where(name: 'free').first
        silver_m_plan = Plan.where(name: 'silver', cycle: 'month').first
        silver_y_plan = Plan.where(name: 'silver', cycle: 'year').first
        gold_m_plan   = Plan.where(name: 'gold', cycle: 'month').first
        gold_y_plan   = Plan.where(name: 'gold', cycle: 'year').first
        
        ::Site.where { (plan_id != nil) | (pending_plan_id != nil) }.find_in_batches(batch_size: 100) do |sites|
          sites.each do |site|
            new_plans = []
            
            %w[plan pending_plan].each_with_index do |p, i|
              new_plans[i] = case site.send p
              when dev_plan
                free_plan
              when comet_m_plan
                silver_m_plan
              when comet_y_plan
                silver_y_plan
              when star_m_plan
                gold_m_plan
              when star_y_plan
                gold_y_plan
              end
            end
            new_attrs = {}
            new_attrs[:plan_id] = new_plans[0].id if new_plans[0].present?
            new_attrs[:pending_plan_id] = new_plans[1].id if new_plans[1].present?
            y new_attrs
            unless new_attrs.empty?
              site.update_attributes(new_attrs)
              total += 1
            end
          end
          puts "500 more..." if total % 500 == 0
        end
        "Finished: in total, #{total} sites were updated!"
      end

    end

  end
end
