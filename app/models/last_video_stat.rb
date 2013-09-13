require 'sublime_video_private_api'

class LastVideoStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  parse_root_in_json :stat, format: :active_model_serializers
  collection_path '/private_api/sites/:site_token/videos/:video_uid/last_video_stats'

  def self.last_stats(video_tag)
    all(_site_token: video_tag.site_token, _video_uid: video_tag.uid)
  end

  def loads
    self['lo']
  end

  def starts
    self['st']
  end
end
