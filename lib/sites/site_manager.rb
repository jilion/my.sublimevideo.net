require_dependency 'addons/addonship_manager'
require_dependency 'sites/rank_manager'
require_dependency 'sites/usage_manager'

module Sites
  class SiteManager < Struct.new(:site)

    def self.build_site(params)
      new params.delete(:user).sites.new(params)
    end

    def save
      Site.transaction do
        if site.save
          set_default_addons(site)
          delay_set_ranks(site)
          update_last_30_days_video_views_counters(site)

          true
        else
          false
        end
      end
    end

    private

    def set_default_addons(site)
      Addons::AddonshipManager.new(site).update_addonships!(logo: 'sublime', support: 'standard')
    end

    def delay_set_ranks(site)
      Sites::RankManager.delay(priority: 100, run_at: Time.now.utc + 30).set_ranks(site.id)
    end

    def update_last_30_days_video_views_counters(site)
      Sites::UsageManager.new(site).update_last_30_days_video_views_counters
    end

  end
end
