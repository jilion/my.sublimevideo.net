require 'sublime_video_private_api'

class SiteStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  parse_root_in_json :stat, format: :active_model_serializers
  collection_path '/private_api/sites/:site_token/site_stats'

  def self.last_days_starts(site, days)
    get_raw(:last_days_starts, _site_token: site.token, days: days)[:parsed_data][:data][:starts]
  end

end
