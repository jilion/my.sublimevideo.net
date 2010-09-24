module Hostname
  class << self
    
    # one hostname or list of hostnames separated by comma
    def clean(hostnames)
      if hostnames.present?
        hostnames.split(',').select { |h| h.present? }.map do |hostname|
          hostname.strip!
          clean_one(hostname)
        end.join(', ')
      else
        hostnames
      end
    end
    
    # one site or list of sites separated by comma
    def valid?(hostnames)
      if hostnames.present?
        clean(hostnames).split(', ').all? { |h| valid_one?(h) }
      end
    end
    
    # one site or list of sites separated by comma
    def dev_valid?(hostnames)
      if hostnames.present?
        clean(hostnames).split(', ').all? { |h| dev_valid_one?(h) }
      else
        true
      end
    end
    
    # one site or list of sites separated by comma
    def wildcard?(hostnames)
      if hostnames.present?
        clean(hostnames).split(', ').any? { |h| h =~ /\*/ }
      end
    end
    
    # one site or list of sites separated by comma
    def duplicate?(hostnames)
      if hostnames.present?
        hostnames = clean(hostnames).split(', ')
        hostnames.count > hostnames.uniq.count
      end
    end
    
    # one site or list of sites separated by comma
    def include?(hostnames, hostname)
      if hostnames.present?
        clean(hostnames).split(', ').any? { |h| h == hostname }
      end
    end
    
  private
    
    def clean_one(hostname)
      hostname.downcase!
      hostname = "http://#{hostname}" unless hostname =~ %r(^\w+://.*$) # made it parseable by URI
      begin
        hostname = URI.parse(hostname).host
        pss = PublicSuffixService.parse(hostname)
        if pss.trd == 'www'
          hostname = [pss.sld, pss.tld].compact.join('.')
        else
          hostname = [pss.trd, pss.sld, pss.tld].compact.join('.')
        end
      rescue
        hostname = hostname.gsub(%r(.+://(www\.)?), '')
      end
      hostname
    end
    
    def valid_one?(hostname)
      ssp = PublicSuffixService.parse(hostname)
      ssp.sld.present?
    rescue
      false
    end
    
    def dev_valid_one?(hostname)
      ssp = PublicSuffixService.parse(hostname)
      ssp.tld == 'local'
    rescue
      true
    end
    
  end
end