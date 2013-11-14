require 'stats_presenter'
require 'site_stat'
require 'last_site_stat'
require 'last_site_play'

class SiteStatsPresenter < StatsPresenter

  def _last_stats_by_hour
    @_last_stats_by_hour ||= SiteStat.last_hours_stats(resource, options[:hours] + 24).reverse
  end

  def _last_stats_by_minute
    @_last_stats_by_minute ||= LastSiteStat.last_stats(resource).reverse
  end

  def last_plays
    @last_plays ||= LastSitePlay.last_plays(resource, options[:since])
  end

  def etag
    "#{resource.token}_#{options}"
  end

end
