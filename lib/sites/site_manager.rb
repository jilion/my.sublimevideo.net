require_dependency 'addons/addonship_manager'
require_dependency 'sites/rank_manager'

module Sites
  class SiteManager < Struct.new(:user)

    def create(site)
      site.user = user

      Site.transaction do
        if site.save
          set_default_addons(site)
          delay_set_ranks(site)
          true
        else
          false
        end
      end
    end

    private

    def set_default_addons(site)
      Addons::AddonshipManager.update_addonships_for_site!(site, logo: 'sublime', support: 'standard')
    end

    def delay_set_ranks(site)
      Sites::RankManager.delay(priority: 100, run_at: Time.now.utc + 30).set_ranks(site.id)
    end

  end
end
