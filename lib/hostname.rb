require 'ipaddr'

module Hostname
  class << self

    # http://en.wikipedia.org/wiki/Pseudo-top-level_domain
    PSEUDO_TLD ||= %w[bitnet csnet exit i2p local onion oz freenet uucp root]

    # one hostname or list of hostnames separated by comma
    def clean(hostnames)
      if hostnames.present?
        hostnames.split(',').select { |h| h.present? }.map do |hostname|
          hostname.strip!
          clean_one(hostname)
        end.sort.join(', ')
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
        pss = PublicSuffix.parse(hostname)
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
      return true if ["blogspot.com", "appspot.com", "operaunite.com"].include?(hostname)
      ssp = PublicSuffix.parse(hostname)
      ssp.sld.present? && !PSEUDO_TLD.include?(ssp.tld)
    rescue
      ipv4?(hostname) && !ipv4_local?(hostname)
    end

    def dev_valid_one?(hostname)
      ssp = PublicSuffix.parse(hostname)
      PSEUDO_TLD.include?(ssp.tld)
    rescue
      !ipv4?(hostname) || ipv4_local?(hostname)
    end

    def ipv4?(hostname)
      begin
        ipaddr = IPAddr.new(hostname)
        ipaddr.ipv4?
      rescue
        false
      end
    end

    def ipv4_local?(hostname)
      begin
        addr = Addrinfo.tcp(hostname, 80)
        hostname == "0.0.0.0" || addr.ipv4_private? || addr.ipv4_loopback?
      rescue
        false
      end
    end

  end
end