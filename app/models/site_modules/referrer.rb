module SiteModules::Referrer
  extend ActiveSupport::Concern

  module ClassMethods

    def referrer_match_hostname?(referrer, hostname, path='', wildcard=false)
      uri      = Addressable::URI.parse(referrer)
      hostname = hostname.gsub('.', '\.')
      if path || wildcard
        path     = Addressable::URI.encode(path)
        uri_path = Addressable::URI.encode(uri.path)
        (uri.host =~ /^(#{wildcard ? '.*' : 'www'}\.)?#{hostname}$/i) && (path.blank? || uri_path =~ /^\/#{path}($|\/.*$)/i)
      else
        uri.host =~ /^(www\.)?#{hostname}$/i
      end
    end

  end

  module InstanceMethods

    def referrer_type(referrer, timestamp=Time.now.utc)
      return "invalid" if referrer.nil? || referrer.length < 10
      if past_site = version_at(timestamp)
        referrer.gsub!(/\[|\]/, '')
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
      # Notify.send("Referrer (#{referrer}), site_id (#{self.id}), timestamp #{timestamp} type could not be guessed: #{ex.message}", :exception => ex)
      "invalid"
    end

    def main_referrer?(referrer)
      hostname.present? && self.class.referrer_match_hostname?(referrer, hostname, path, wildcard)
    end

    def extra_referrer?(referrer)
      extra_hostnames.present? && extra_hostnames.split(', ').any? { |h| self.class.referrer_match_hostname?(referrer, h, path, wildcard) }
    end

    def dev_referrer?(referrer)
      dev_hostnames.present? && dev_hostnames.split(', ').any? { |h| self.class.referrer_match_hostname?(referrer, h, '', wildcard) }
    end

  end

end
