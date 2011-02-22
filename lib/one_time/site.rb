module OneTime
  module Site

    class << self

      # Method used in the 'one_time:update_invalid_sites' rake task
      # SITES MUST BE IN THE BETA PLAN BEFORE RUNNING THIS METHOD (OTHERWISE, BLANK DOMAINS WILL NOT BE ACCEPTED)!!
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

          site.hostname        = Hostname.clean(site.hostname) if site.hostname.present?
          site.dev_hostnames   = Hostname.clean(new_dev_hostnames.sort.join(', '))
          site.extra_hostnames = Hostname.clean(extra_hostnames.sort.join(', ')) if extra_hostnames.present?
          site.cdn_up_to_date  = site.valid? # will reload the site's license if site is valid
          repaired_sites += 1 if site.save!

          result << "##{site.id} (#{'still in' unless site.valid?}valid)"
          result << "MAIN : #{site.hostname.inspect} (#{'in' unless Hostname.valid?(site.hostname)}valid)"
          result << "DEV  : #{old_dev_hostnames.join(", ").inspect} => #{site.dev_hostnames.inspect}"
          result << "EXTRA: #{site.extra_hostnames.inspect}\n\n"
        end

        result << "[After] #{invalid_sites.size - repaired_sites} invalid sites remaining!!"
        result
      end

      def set_beta_plan
        ::Site.with_state(:active).update_all(:plan_id => Plan.find_by_name("beta").id)
        "#{::Site.beta.count} beta sites (on #{::Site.count} total sites)."
      end

      def rollback_beta_sites_to_dev
        beta_sites_ids = ::Site.beta.all.map(&:id)
        ::Site.where(:id => beta_sites_ids).update_all(:plan_id => Plan.find_by_name("dev").id)
      end

    end

  end
end
