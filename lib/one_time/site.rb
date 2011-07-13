module OneTime
  module Site

    class << self

      def rollback_beta_sites_to_dev
        total = 0
        beta_sites_ids = ::Site.beta.where(pending_plan_id: nil).select("sites.id").map(&:id)
        ::Site.where(id: beta_sites_ids).update_all(plan_id: ::Plan.dev_plan.id)

        ::Site.where(id: beta_sites_ids).find_in_batches(:batch_size => 100) do |sites|
          sites.each do |site|
            ::Site.delay.update_loader_and_license(site.id, { loader: false, license: true })
          end
          total += sites.count
        end
        "Finished: in total, #{total} sites will have their license re-generated"
      end

      def regenerate_all_loaders_and_licenses
        total = 0
        ::Site.active.find_in_batches(:batch_size => 100) do |sites|
          sites.each do |site|
            ::Site.delay.update_loader_and_license(site.id, { loader: true, license: true })
          end
          total += sites.count
        end
        "Finished: in total, #{total} sites will have their loader and license re-generated"
      end

    end

  end
end
