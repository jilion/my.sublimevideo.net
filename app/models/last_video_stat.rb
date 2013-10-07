require 'last_stat'

class LastVideoStat
  include LastStat

  collection_path '/private_api/last_video_stats'

  def self.last_stats(video_tag)
    params = { site_token: video_tag.site_token, video_uid: video_tag.uid }

    all(params).per(60)
  end
end
