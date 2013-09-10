require 'sublime_video_private_api'

class VideoStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  collection_path '/private_api/sites/:site_token/video_stats'

  def self.last_hours_stats(video_tag, hours)
    find(video_tag.uid, _site_token: video_tag.site_token, hours: hours)[:stats]
  end
end
