module OneTime
  module Site

    class << self

      def set_beta_plan
        ::Site.where({ plan_id: nil }, { hostname: nil } | { hostname: '' }).update_all(:plan_id => Plan.find_by_name("dev").id)
        ::Site.where({ plan_id: nil }, { :hostname.ne => nil } | { :hostname.ne => '' }).update_all(:plan_id => Plan.find_by_name("beta").id)
        "#{::Site.dev.count} sites are now using the Dev plan (on #{::Site.not_archived.count} non-archived sites)."
        "#{::Site.beta.count} sites are now using the Beta plan (on #{::Site.not_archived.count} non-archived sites)."
      end

      # Method used in the 'one_time:update_invalid_sites' rake task
      def update_hostnames
        invalid_sites = ::Site.not_archived.reject { |s| s.valid? }

        result = []
        repaired_sites = 0
        result << "[Before] #{invalid_sites.size} invalid sites, let's try to repair them!\n\n"

        invalid_sites.each do |site|
          old_dev_hostnames = site.dev_hostnames.split(', ')
          new_dev_hostnames = []
          extra_hostnames   = []

          old_dev_hostnames.each do |dev_hostname|
            next if Hostname.duplicate?([site.hostname, dev_hostname].join(', '))

            if Hostname.dev_valid?(dev_hostname)
              new_dev_hostnames << dev_hostname
            elsif Hostname.extra_valid?(dev_hostname)
              extra_hostnames << dev_hostname
            end
          end

          if !Hostname.valid?(site.hostname) && Hostname.dev_valid?(site.hostname)
            new_dev_hostnames << site.hostname
            site.hostname = nil
          end

          new_dev_hostnames.uniq!
          extra_hostnames.uniq!

          site.hostname        = site.hostname.present? ? Hostname.clean(site.hostname) : (extra_hostnames.present? ? extra_hostnames.pop : nil)
          site.dev_hostnames   = Hostname.clean(new_dev_hostnames.sort.join(', ')) if new_dev_hostnames
          site.extra_hostnames = Hostname.clean(extra_hostnames.sort.join(', ')) if extra_hostnames.present?
          site.cdn_up_to_date  = site.valid? # will reload the site's license if site is valid
          repaired_sites += 1 if site.save!(validate: false)

          result << "##{site.id} (#{'still in' unless site.valid?}valid)"
          result << "MAIN : #{site.hostname.inspect} (#{'in' unless Hostname.valid?(site.hostname)}valid)"
          result << "DEV  : #{old_dev_hostnames.join(", ").inspect} => #{site.dev_hostnames.inspect}"
          result << "EXTRA: #{site.extra_hostnames.inspect}\n\n"
        end

        result << "[After] #{invalid_sites.size - repaired_sites} invalid sites remaining!!"
        result
      end

      def rollback_beta_sites_to_dev
        beta_sites_ids = ::Site.beta.all.map(&:id)
        ::Site.where(:id => beta_sites_ids).update_all(:plan_id => Plan.find_by_name("dev").id)
      end

      def regenerate_all_loaders_and_licenses
        total = 0
        ::Site.active.find_in_batches(:batch_size => 100) do |sites|
          sites.each do |site|
            ::Site.delay.update_loader_and_license(site.id, { loader: true, license: true })
          end
          puts "#{sites.count} sites will have their loader and license re-generated"
          total += sites.count
        end
        "Finished: in total, #{total} sites will have their loader and license re-generated"
      end

    end

  end
end
