require 'sublime_video_private_api'

class LastVideoStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  collection_path '/private_api/last_video_stats'

  def self.last_stats(video_tag)
    params = { site_token: video_tag.site_token, video_uid: video_tag.uid }

    all(params)
  end

  def time
    Time.parse(t)
  end
end
