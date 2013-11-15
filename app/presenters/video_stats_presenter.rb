require 'stats_presenter'
require 'video_stat'
require 'last_video_stat'
require 'last_video_play'

class VideoStatsPresenter < StatsPresenter

  def etag
    "#{resource.uid}_#{options}"
  end

end
