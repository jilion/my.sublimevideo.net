require 'last_play'

class LastVideoPlay < LastPlay
  collection_path '/private_api/last_plays'

  def self.last_plays(video_tag, since = nil)
    params = { site_token: video_tag.site_token, video_uid: video_tag.uid }
    params[:since] = since if since.present?

    all(params)
  end

end
