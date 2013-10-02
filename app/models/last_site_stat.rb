require 'last_stat'

class LastSiteStat < LastStat
  parse_root_in_json :stat, format: :active_model_serializers
  collection_path '/private_api/sites/:site_token/last_site_stats'

  def self.last_stats(site)
    params = { _site_token: site.token }

    all(params)
  end
end
