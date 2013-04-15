require 'ipaddr'

class HostnameHandler

  # http://en.wikipedia.org/wiki/Pseudo-top-level_domain
  PSEUDO_TLD ||= %w[bitnet csnet exit i2p local onion oz freenet uucp root]

  # one hostname or list of hostnames separated by comma
  def self.clean(hostnames)
    if hostnames.present?
      hostnames.split(/,\s*/).select { |h| h.present? }.map do |hostname|
        hostname.strip!
        clean_one(hostname)
      end.sort.join(', ')
    else
      hostnames
    end
  end

  def self.main_invalid?(*args)
    !_main_valid?(args.shift)
  end

  def self.extra_invalid?(*args)
    !_extra_valid?(args.shift)
  end

  def self.dev_invalid?(*args)
    !_dev_valid?(args.shift)
  end

  # one site or list of sites separated by comma
  def self.wildcard?(*args)
    hostnames = args.shift

    clean(hostnames).split(/,\s*/).any? { |h| h =~ /\*/ } if hostnames.present?
  end

  # one site or list of sites separated by comma
  def self.duplicate?(*args)
    hostnames = args.shift
    if hostnames.present?
      hostnames = clean(hostnames).split(/,\s*/)
      hostnames.count > hostnames.uniq.count
    end
  end

  # one site or list of sites separated by comma
  def self.include_hostname?(*args)
    hostnames = args.shift
    record = args.shift

    clean(hostnames).split(/,\s*/).any? { |h| h == record.try(:hostname) } if hostnames.present?
  end

  def self.detect_error(*args)
    record = args.shift
    hostnames = args.shift
    args.find { |validation| send("#{validation}?", hostnames, record) }
  end

  private

  def self._main_valid?(hostnames)
    clean(hostnames).split(/,\s*/).all? { |h| valid_one?(h) } if hostnames.present?
  end

  # one site or list of sites separated by comma
  def self._extra_valid?(hostnames)
    if hostnames.present?
      clean(hostnames).split(/,\s*/).all? { |h| valid_one?(h) }
    else
      true
    end
  end

  # one site or list of sites separated by comma
  def self._dev_valid?(hostnames)
    if hostnames.present?
      clean(hostnames).split(/,\s*/).all? { |h| dev_valid_one?(h) }
    else
      true
    end
  end

  def self.clean_one(hostname)
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

  def self.valid_one?(hostname)
    hostname.strip!
    return true if %w[blogspot.com appspot.com operaunite.com].include?(hostname)
    ssp = PublicSuffix.parse(hostname)
    ssp.sld.present? && !PSEUDO_TLD.include?(ssp.tld)
  rescue
    ipv4?(hostname) && !ipv4_local?(hostname)
  end

  def self.dev_valid_one?(hostname)
    ssp = PublicSuffix.parse(hostname)
    PSEUDO_TLD.include?(ssp.tld)
  rescue
    !ipv4?(hostname) || ipv4_local?(hostname)
  end

  def self.ipv4?(hostname)
    begin
      ipaddr = IPAddr.new(hostname)
      ipaddr.ipv4?
    rescue
      false
    end
  end

  def self.ipv4_local?(hostname)
    begin
      addr = Addrinfo.tcp(hostname, 80)
      hostname == '0.0.0.0' || addr.ipv4_private? || addr.ipv4_loopback?
    rescue
      false
    end
  end
end
