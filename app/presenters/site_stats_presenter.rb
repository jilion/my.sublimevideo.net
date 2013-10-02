require 'stats_presenter'
require 'site_stat'
require 'last_site_stat'
require 'last_site_play'

class SiteStatsPresenter < StatsPresenter

  def last_stats_by_hour
    @last_stats_by_hour ||= SiteStat.last_hours_stats(object, options[:hours])
  end

  def last_stats_by_minute
    @last_stats_by_minute ||= LastSiteStat.last_stats(object)
  end

  def last_plays
    @last_plays ||= LastSitePlay.last_plays(object, options[:since])
  end

  def etag
    "#{object.token}_#{options}"
  end

end
