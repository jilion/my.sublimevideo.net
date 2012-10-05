require_dependency 'services/sites'
require_dependency 'services/sites/addonship'
require_dependency 'services/sites/rank'
require_dependency 'services/sites/usage'

Services::Sites::Manager = Struct.new(:site) do
  class << self

    def build_site(params)
      new params.delete(:user).sites.new(params)
    end

  end

  def save
    Site.transaction do
      if site.save
        # set_default_addons(site)
        delay_set_ranks(site)
        # update_last_30_days_video_views_counters(site)

        true
      else
        false
      end
    end
  end

  private

  def set_default_addons(site)
    Services::Sites::Addonship.new(site).update_addonships!(logo: 'sublime', support: 'standard')
  end

  def delay_set_ranks(site)
    Services::Sites::Rank.delay(priority: 100, run_at: Time.now.utc + 30).set_ranks(site.id)
  end

  # def update_last_30_days_video_views_counters(site)
  #   Services::Sites::Usage.new(site).update_last_30_days_video_views_counters
  # end

end
