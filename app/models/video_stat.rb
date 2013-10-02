require 'stat'

class VideoStat < Stat
  collection_path '/private_api/sites/:site_token/videos/:video_uid/video_stats'
  parse_root_in_json :stat, format: :active_model_serializers

  def self.last_hours_stats(video_tag, hours)
    all(_site_token: video_tag.site_token, _video_uid: video_tag.uid, hours: hours).per(24*365)
  end
end
