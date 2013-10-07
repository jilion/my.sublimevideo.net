require 'last_stat'

class LastSiteStat < LastStat
  collection_path '/private_api/last_site_stats'

  def self.last_stats(site)
    params = { site_token: site.token }

    all(params).per(60)
  end
end
