require 'last_stat'

class LastVideoStat < LastStat
  parse_root_in_json :stat, format: :active_model_serializers
  collection_path '/private_api/sites/:site_token/videos/:video_uid/last_video_stats'

  def self.last_stats(video_tag)
    params = { _site_token: video_tag.site_token, _video_uid: video_tag.uid }

    all(params)
  end
end
