require 'last_play'

class LastSitePlay < LastPlay
  collection_path '/private_api/last_plays'

  def self.last_plays(site, since = nil)
    params = { site_token: site.token }
    params[:since] = since if since.present?

    all(params)
  end

end
