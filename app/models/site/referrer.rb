module Site::Referrer

  # ====================
  # = Instance Methods =
  # ====================

  def referrer_type(referrer, timestamp = Time.now.utc)
    if past_site = version_at(timestamp)
      referrer.gsub! /\[|\]/, ''
      if past_site.main_referrer?(referrer)
        "main"
      elsif past_site.extra_referrer?(referrer)
        "extra"
      elsif past_site.dev_referrer?(referrer)
        "dev"
      else
        "invalid"
      end
    else
      Notify.send("No past site for id #{self.id}, timestamp #{timestamp}")
    end
  rescue => ex
    Notify.send("Referrer (#{referrer}), site_id (#{self.id}), timestamp #{timestamp} type could not be guessed: #{ex.message}", :exception => ex)
    "invalid"
  end

  def main_referrer?(referrer)
    hostname.present? && Site::Referrer.referrer_match_hostname?(referrer, hostname, path, wildcard)
  end

  def extra_referrer?(referrer)
    extra_hostnames.present? && extra_hostnames.split(', ').any? { |h| Site::Referrer.referrer_match_hostname?(referrer, h, path, wildcard) }
  end

  def dev_referrer?(referrer)
    dev_hostnames.present? && dev_hostnames.split(', ').any? { |h| Site::Referrer.referrer_match_hostname?(referrer, h, '', wildcard) }
  end

private

  # =================
  # = Class Methods =
  # =================

  def self.referrer_match_hostname?(referrer, hostname, path = '', wildcard = false)
    referrer = parse_uri(referrer)
    hostname = hostname.gsub('.', '\.')
    if path || wildcard
      (referrer.host =~ /^(#{wildcard ? '.*' : 'www'}\.)?#{hostname}$/i) && (path.blank? || referrer.path =~ /^\/#{URI.encode(path)}($|\/.*$)/i)
    else
      referrer.host =~ /^(www\.)?#{hostname}$/i
    end
  end

  def self.parse_uri(uri)
    uri = URI.encode(uri)
    begin
      URI.parse(uri)
    rescue
      FakeURI.parse(uri)
    end
  end

end

Site.send :include, Site::Referrer