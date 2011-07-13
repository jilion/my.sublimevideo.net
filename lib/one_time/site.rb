module OneTime
  module Site

    class << self

      def rollback_beta_sites_to_dev
        total = 0
        beta_sites_ids = ::Site.beta.where(pending_plan_id: nil).select("sites.id").map(&:id)
        ::Site.where(id: beta_sites_ids).update_all(plan_id: ::Plan.dev_plan.id)

        ::Site.where(id: beta_sites_ids).find_in_batches(batch_size: 100) do |sites|
          sites.each do |site|
            ::Site.delay(priority: 200).update_loader_and_license(site.id, { loader: false, license: true })
          end
          total += sites.count
        end
        "Finished: in total, #{total} sites will have their license re-generated"
      end

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

      def move_local_ip_from_hostname_and_extra_domains_to_dev_domains
        total = 0
        ::Site.active.find_in_batches(batch_size: 100) do |sites|
          sites.each do |site|
            old_dev_hostnames = site.dev_hostnames.try(:split, ', ') || []
            new_dev_hostnames = []

            if Hostname.send(:dev_valid_one?, site.hostname)
              new_dev_hostnames << site.hostname
              site.hostname = ''
            end

            new_extra_hostnames = site.extra_hostnames.try(:split, ', ') || []
            (site.extra_hostnames.try(:split, ', ') || []).each do |extra_hostname|
              if Hostname.send(:dev_valid_one?, extra_hostname)
                new_dev_hostnames << extra_hostname
                new_extra_hostnames.delete(extra_hostname)
              end
            end

            if new_dev_hostnames.any?
              site.dev_hostnames   = (old_dev_hostnames + new_dev_hostnames).uniq.compact.sort.join(', ')
              site.extra_hostnames = new_extra_hostnames.uniq.compact.sort.join(', ')
              site.save_without_password_validation
              total += 1
            end
          end
          puts "500 more..." if total % 500 == 0
        end
        "Finished: in total, #{total} sites were fixed"
      end

    end

  end
end
