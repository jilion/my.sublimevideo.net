require 'sidekiq'

class StatsSponsorerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'my-low'

  def perform(site_token)
    if site = Site.where(token: site_token).first
      SiteManager.new(site).update_billable_items({}, { 'stats' => AddonPlan.get('stats', 'realtime').id }, { force: 'sponsored' })
    end
  end
end
