require 'sublime_video_private_api'

class SiteAdminStat
  include SublimeVideoPrivateApi::Model
  uses_private_api :stats
  collection_path '/private_api/site_admin_stats'

  def self.last_days_starts(site, days)
    get_raw(:last_days_starts, site_token: site.token, days: days)[:parsed_data][:data]
  end

  def self.last_pages(site)
    get_raw(:last_pages, site_token: site.token)[:parsed_data][:data]
  end

  def self.total_admin_starts(site)
    _all_time_stats(site).sum { |stat| stat.starts.values.sum }
  end

  def self.total_admin_app_loads(site)
    _all_time_stats(site).sum { |stat| stat.app_loads.values.sum }
  end

  def self.last_30_days_admin_app_loads(site, type)
    all(site_token: site.token, days: 30).sum { |stat| stat.app_loads[type.to_s].to_i }
  end

  def self.global_day_stat(day)
    get_raw(:global_day_stat, day: day)[:parsed_data][:data]
  end

  def self.last_30_days_sites_with_starts(day, threshold: 100)
    get_raw(:last_30_days_sites_with_starts, day: day, threshold: threshold)[:parsed_data][:data][:count]
  end

  def date
    t.to_date
  end

  def app_loads
    try(:al) || {}
  end

  def loads
    try(:lo) || {}
  end

  def starts
    try(:st) || {}
  end

  private

  def self._all_time_stats(site)
    all_days = ((Time.now.utc.end_of_day - Time.utc(2011,11,29)) / 1.day).ceil
    all(site_token: site.token, per: all_days)
  end
end
