module OneTime
  module Site
    
    class << self
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
          
          new_dev_hostnames.uniq!
          extra_hostnames.uniq!
          
          if (new_dev_hostnames != old_dev_hostnames) || extra_hostnames.present?
            site.hostname        = Hostname.clean(site.hostname)
            site.dev_hostnames   = Hostname.clean(new_dev_hostnames.sort.join(', '))
            site.extra_hostnames = Hostname.clean(extra_hostnames.sort.join(', '))
            site.save(:validate => false)
            if site.valid?
              site.delay.activate
              repaired_sites += 1
            end
          end
          result << "##{site.id} (#{'still in' unless site.valid?}valid)"
          result << "MAIN : #{site.hostname} (#{'in' unless Hostname.valid?(site.hostname)}valid)"
          result << "DEV  : #{old_dev_hostnames.join(", ").inspect} => #{site.dev_hostnames.inspect}"
          result << "EXTRA: #{site.extra_hostnames.inspect}\n\n"
        end
        
        result << "[After] #{invalid_sites.size - repaired_sites} invalid sites remaining!!"
        result
      end
    end
    
  end
end