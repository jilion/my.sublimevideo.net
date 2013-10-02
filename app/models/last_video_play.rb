require 'last_play'

class LastVideoPlay < LastPlay
  collection_path '/private_api/sites/:site_token/videos/:video_uid/last_plays'
  parse_root_in_json :play, format: :active_model_serializers

  def self.last_plays(video_tag, since = nil)
    params = { _site_token: video_tag.site_token, _video_uid: video_tag.uid }
    params[:since] = since if since.present?

    all(params)
  end

end
