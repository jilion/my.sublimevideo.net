require 'sublime_video_private_api'

class VideoStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  collection_path '/private_api/video_stats'

  def self.last_hours_stats(video_tag, hours)
    all(site_token: video_tag.site_token, video_uid: video_tag.uid, hours: hours).per(24*365)
  end

  def time
    Time.parse(t)
  end
end
