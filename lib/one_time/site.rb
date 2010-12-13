module OneTime
  module Site
    
    STAFF_EMAILS = ["mehdi@jilion.com", "zeno@jilion.com", "thibaud@jilion.com", "octave@jilion.com", "remy@jilion.com"]
    
    class << self
      
      # Method used in the 'one_time:update_invalid_sites' rake task
      def update_hostnames(staff = true)
        invalid_sites = ::Site
        invalid_sites = invalid_sites.includes(:user).where(:users => { :email => STAFF_EMAILS }) if staff
        invalid_sites = invalid_sites.not_archived.reject { |s| s.valid? }
        
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
          site.cdn_up_to_date  = true
          repaired_sites += 1 if site.save
          
          result << "##{site.id} (#{'still in' unless site.valid?}valid)"
          result << "MAIN : #{site.hostname} (#{'in' unless Hostname.valid?(site.hostname)}valid)"
          result << "DEV  : #{old_dev_hostnames.join(", ").inspect} => #{site.dev_hostnames.inspect}"
          result << "EXTRA: #{site.extra_hostnames.inspect}\n\n"
        end
        
        result << "[After] #{invalid_sites.size - repaired_sites} invalid sites remaining!!"
        result
      end
      
      def set_beta_state(staff = true)
        sites = ::Site
        sites = sites.joins(:user).where(:users => { :email => STAFF_EMAILS }) if staff
        
        ::Site.where(:id => sites.all.map(&:id)).update_all(:state => 'beta')
        "#{::Site.where(:state => 'beta').count} beta sites (on #{::Site.count} total sites)."
      end
      
    end
    
  end
end