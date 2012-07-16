module OneTime
  module Site

    class << self

      def regenerate_templates(options)
        scheduled, delay = 0, 5
        ::Site.active.find_each(batch_size: 100) do |site|
          ::Site.delay(priority: 200, run_at: delay.seconds.from_now).update_loader_and_license(site.id, options)
          scheduled += 1

          if (scheduled % 500).zero?
            puts "#{scheduled} sites scheduled..."
            delay += 5
          end
        end

        "Finished: in total, #{scheduled} sites will have their loader and license re-generated"
      end
      
      def update_sites_in_trial_to_new_trial_plan
        trial_plan_id, modified = Plan.trial_plan.id, 0
        ::Site.not_archived.where { (trial_started_at != nil) & (trial_started_at > 14.days.ago) }.each do |site|
          site.plan_started_at = site.trial_started_at
          site.send(:write_attribute, :plan_id, trial_plan_id)
          site.save!
          modified += 1
        end

        "Finished: in total, #{modified} sites are now in the new trial."
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
