module Site::Referrer

  # ====================
  # = Instance Methods =
  # ====================

  def referrer_type(referrer, timestamp = Time.now.utc)
    past_site = version_at(timestamp)
    if past_site.main_referrer?(referrer)
      "main"
    elsif past_site.extra_referrer?(referrer)
      "extra"
    elsif past_site.dev_referrer?(referrer)
      "dev"
    else
      "invalid"
    end
  rescue => ex
    Notify.send("Referrer type could not be guessed: #{ex.message}", :exception => ex)
    "invalid"
  end

  def main_referrer?(referrer)
    Site::Referrer.referrer_match_hostname?(referrer, hostname, path, wildcard)
  end

  def extra_referrer?(referrer)
    extra_hostnames.split(', ').any? { |h| Site::Referrer.referrer_match_hostname?(referrer, h, path, wildcard) }
  end

  def dev_referrer?(referrer)
    dev_hostnames.split(', ').any? { |h| Site::Referrer.referrer_match_hostname?(referrer, h, '', wildcard) }
  end

private

  # =================
  # = Class Methods =
  # =================

  def self.referrer_match_hostname?(referrer, hostname, path = '', wildcard = false)
    referrer = URI.parse(referrer)
    hostname = hostname.gsub('.', '\.')
    if path || wildcard
      (referrer.host =~ /^(#{wildcard ? '.*' : 'www'}\.)?#{hostname}$/i) && (path.blank? || referrer.path =~ /^\/#{path}($|\/.*$)/i)
    else
      referrer.host =~ /^(www\.)?#{hostname}$/i
    end
  end

end

Site.send :include, Site::Referrer