require 'stat'

class SiteStat < Stat
  collection_path '/private_api/site_stats'

  def self.last_hours_stats(site, hours)
    all(site_token: site.token, hours: hours).per(24*365)
  end

  def self.last_days_starts(site, days)
    get_raw(:last_days_starts, site_token: site.token, days: days)[:parsed_data][:data]
  end
end
