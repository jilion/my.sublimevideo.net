require 'last_play'

class LastSitePlay < LastPlay
  collection_path '/private_api/sites/:site_token/last_plays'
  parse_root_in_json :play, format: :active_model_serializers

  def self.last_plays(site, since = nil)
    params = { _site_token: site.token }
    params[:since] = since if since.present?

    all(params)
  end

end
