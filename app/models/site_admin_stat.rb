require 'sublime_video_private_api'

class SiteAdminStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  # parse_root_in_json :stat, format: :active_model_serializers
  collection_path '/private_api/sites/:site_token/site_admin_stats'

  def self.last_days_starts(site, days)
    get_raw(:last_days_starts, _site_token: site.token, days: days)[:parsed_data][:data][:starts]
  end

  def self.last_pages(site)
    get_raw(:last_pages, _site_token: site.token)[:parsed_data][:data][:pages]
  end

  def self.last_stats(site, params = {})
    all(_site_token: site.token, days: params[:days] || 5)
  end
end
