require 'stat'

class SiteStat < Stat
  collection_path '/private_api/sites/:site_token/site_stats'
  parse_root_in_json :stat, format: :active_model_serializers

  def self.last_hours_stats(site, hours)
    all(_site_token: site.token, hours: hours).per(24*365)
  end

  def self.last_days_starts(site, days)
    get_raw(:last_days_starts, _site_token: site.token, days: days)[:parsed_data][:data][:starts]
  end
end
