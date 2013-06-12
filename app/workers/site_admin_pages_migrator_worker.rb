require 'sidekiq'

class SiteAdminPagesMigratorWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'stats'

  def perform(site_token, pages)
    # method handled in stsv
  end
end
