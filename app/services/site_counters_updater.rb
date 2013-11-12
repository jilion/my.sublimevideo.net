class SiteCountersUpdater
  attr_reader :site

  def initialize(site)
    @site = site
  end

  def self.update_not_archived_sites
    Site.not_archived.select(:id).find_each do |site|
      delay(queue: 'my-low').update(site.id)
    end
  end

  def self.update(site_id)
    site = Site.find(site_id)
    new(site).update
  end

  def update
    _update_admin_starts
    _set_first_admin_starts_on
    _update_starts
    _update_video_tags
    site.save
  end

  private

  def _update_admin_starts
    last_admin_starts = SiteAdminStat.last_days_starts(site, 30)
    site.last_30_days_admin_starts = last_admin_starts.sum
  end

  def _set_first_admin_starts_on
    if site.first_admin_starts_on.nil? && site.last_30_days_admin_starts > 0
      site.first_admin_starts_on = Date.yesterday
    end
  end

  def _update_starts
    if _realtime_stats?
      last_starts = site.last_30_days_admin_starts > 0 ? SiteStat.last_days_starts(site, 30) : 30.times.map { 0 }
    else
      last_starts = []
    end
    site.last_30_days_starts_array = last_starts
    site.last_30_days_starts = last_starts.present? ? last_starts.sum : nil
  end

  def _update_video_tags
    if site.last_30_days_admin_starts > 0
      last_video_tags = VideoTag.count(site_token: site.token, last_30_days_active: true, with_valid_uid: true)
    else
      last_video_tags = 0
    end
    site.last_30_days_video_tags = last_video_tags
  end

  def _realtime_stats?
    site.subscribed_to?(AddonPlan.get('stats', 'realtime'))
  end

end
