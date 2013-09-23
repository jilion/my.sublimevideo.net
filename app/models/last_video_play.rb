require 'sublime_video_private_api'

class LastVideoPlay
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  parse_root_in_json :play, format: :active_model_serializers
  collection_path '/private_api/sites/:site_token/videos/:video_uid/last_plays'

  def self.last_plays(video_tag, since = nil)
    params = { _site_token: video_tag.site_token, _video_uid: video_tag.uid }
    params[:since] = since if since.present?

    all(params)
  end
end
