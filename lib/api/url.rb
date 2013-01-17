module Api
  class Url
    def initialize(subdomain)
      @subdomain = subdomain.to_s
    end

    def url
      scheme + [subdomain, host].compact.join('.') + '/api'
    end

    private

    def subdomain
      @subdomain == 'www' ? nil : @subdomain
    end

    def host
      case Rails.env
      when 'development' then 'sublimevideo.dev'
      when 'production'  then 'sublimevideo.net'
      when 'staging'     then 'sublimevideo-staging.net'
      when 'test'        then 'sublimevideo.dev'
      end
    end

    def scheme
      case Rails.env
      when 'development', 'test'   then 'http://'
      when 'production', 'staging' then 'https://'
      end
    end
  end
end
