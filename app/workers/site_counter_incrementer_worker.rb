require 'sidekiq'

class SiteCounterIncrementerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'my-low'

  def perform(site_token, counter_name)
    if site = Site.where(token: site_token).first
      site.increment!(counter_name)
    end
  end
end
