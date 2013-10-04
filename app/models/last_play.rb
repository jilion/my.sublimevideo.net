require 'sublime_video_private_api'

class LastPlay
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  collection_path '/private_api/last_plays'

  def self.last_plays(video_tag, since = nil)
    params = { site_token: video_tag.site_token, video_uid: video_tag.uid }
    params[:since] = since if since.present?

    all(params)
  end

  def time
    Time.parse(t)
  end

  def document_url
    ERB::Util.h(du)
  end

  def referrer_url
    ERB::Util.h(ru)
  end

  def referrer_url?
    ru?
  end

end
