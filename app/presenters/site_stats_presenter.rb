require 'stats_presenter'
require 'site_stat'
require 'last_site_stat'
require 'last_site_play'

class SiteStatsPresenter < StatsPresenter

  def etag
    "#{resource.token}_#{options}"
  end

end
