require 'stats_presenter'
require 'site_stat'
require 'last_site_stat'
require 'last_site_play'

class SiteStatsPresenter < StatsPresenter

  def last_stats_by_hour
    @last_stats_by_hour ||= SiteStat.last_hours_stats(resource, options[:hours])
  end

  def last_stats_by_minute
    @last_stats_by_minute ||= LastSiteStat.last_stats(resource)
  end

  def last_plays
    @last_plays ||= LastSitePlay.last_plays(resource, options[:since])
  end

  def etag
    "#{resource.token}_#{options}"
  end

end
