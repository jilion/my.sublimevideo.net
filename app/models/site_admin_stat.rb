require 'sublime_video_private_api'
require 'active_record/errors'
require 'rescue_me'

class SiteAdminStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  collection_path '/private_api/site_admin_stats'

  def self.migration_totals(site_token, params = {})
    rescue_and_retry(3) do
      get_raw(:migration_totals, params.merge(site_token: site_token))[:parsed_data][:data][:totals]
    end
  end
end
