require 'stat'

class VideoStat
  include Stat

  collection_path '/private_api/video_stats'

  def self.last_hours_stats(video_tag, hours)
    all(site_token: video_tag.site_token, video_uid: video_tag.uid, hours: hours).per(24*365)
  end
end
