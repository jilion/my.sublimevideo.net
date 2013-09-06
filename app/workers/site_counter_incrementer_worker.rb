require 'sidekiq'

class SiteCounterIncrementerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default'

  def perform(site_token, counter_name)
    site = Site.where(token: site_token).first!
    site.increment!(counter_name)
  end
end
