require 'video_stat'
require 'last_video_stat'
require 'last_video_play'

class VideoStatsPresenter < StatsPresenter

  def last_stats_by_hour
    @last_stats_by_hour ||= VideoStat.last_hours_stats(resource, options[:hours])
  end

  def last_stats_by_minute
    @last_stats_by_minute ||= LastVideoStat.last_stats(resource)
  end

  def last_plays
    @last_plays ||= LastVideoPlay.last_plays(resource, options[:since])
  end

  def etag
    "#{resource.uid}_#{options}"
  end

end
