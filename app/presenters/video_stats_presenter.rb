require 'stats_presenter'
require 'video_stat'
require 'last_video_stat'
require 'last_video_play'

class VideoStatsPresenter < StatsPresenter

  def _last_stats_by_hour
    @_last_stats_by_hour ||= VideoStat.last_hours_stats(resource, options[:hours] + 24).reverse
  end

  def _last_stats_by_minute
    @_last_stats_by_minute ||= LastVideoStat.last_stats(resource).reverse
  end

  def last_plays
    @last_plays ||= LastVideoPlay.last_plays(resource, options[:since])
  end

  def etag
    "#{resource.uid}_#{options}"
  end

end
