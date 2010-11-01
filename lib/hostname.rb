require 'ipaddr'

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
    def extra_valid?(hostnames)
      if hostnames.present?
        clean(hostnames).split(', ').all? { |h| valid_one?(h) }
      else
        true
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
      hostname.gsub!(%r(^.+://), '')
      begin
        pss = PublicSuffixService.parse(hostname)
        if pss.trd == 'www'
          hostname = [pss.sld, pss.tld].compact.join('.')
        else
          hostname = [pss.trd, pss.sld, pss.tld].compact.join('.')
        end
      rescue
        hostname.gsub!(%r(^www\.), '')
        hostname.gsub!(%r(:.*), '')
        hostname.gsub!(%r(\?.*), '')
        hostname.gsub!(%r(\/.*), '')
      end
      hostname
    end
    
    def valid_one?(hostname)
      ssp = PublicSuffixService.parse(hostname)
      ssp.sld.present? && ssp.tld != 'local'
    rescue
      begin 
        ipaddr = IPAddr.new(hostname)
        ipaddr.ipv4? || ipaddr.ipv6?
      rescue
        false
      end
    end
    
    def dev_valid_one?(hostname)
      ssp = PublicSuffixService.parse(hostname)
      ssp.tld == 'local'
    rescue
      true
    end
    
  end
end