class SiteCountersUpdater
  attr_reader :site

  def initialize(site)
    @site = site
  end

  # =====================
  # = Scheduled methods =
  # =====================
  def self.set_first_billable_plays_at_for_not_archived_sites
    Site.not_archived.where(first_billable_plays_at: nil).select(:id).find_each do |site|
      delay(queue: 'low')._set_first_billable_plays_at(site.id)
    end
  end

  def self.update_last_30_days_counters_for_not_archived_sites
    Site.not_archived.select(:id).find_each do |site|
      at = rand(10_000).seconds.from_now.to_i
      delay(queue: 'low', at: at)._update_last_30_days_counters(site.id)
    end
  end

  # ===========================
  # = Public instance methods =
  # ===========================
  def set_first_billable_plays_at
    if stat = site.day_stats.order_by(d: 1).entries.find { |s| s.billable_vv >= 10 }
      site.update_column(:first_billable_plays_at, stat.respond_to?(:d) ? stat.d : stat.day)
    end
  end

  def update_last_30_days_counters
    columns = { updated_at: Time.now.utc }
    columns.merge!(_last_30_days_video_tags_counters_column)
    columns.merge!(_last_30_days_video_views_counters_columns)
    site.update_columns(columns)
  end

  private

  # Delayed method
  def self._set_first_billable_plays_at(site_id)
    new(Site.find(site_id)).set_first_billable_plays_at
  end

  # Delayed method
  def self._update_last_30_days_counters(site_id)
    new(Site.find(site_id)).update_last_30_days_counters
  end

  def _last_30_days_video_tags_counters_column
    video_tags_count = VideoTag.count(site_token: site.token, last_30_days_active: true, with_valid_uid: true)
    { last_30_days_video_tags: video_tags_count }
  end

  def _last_30_days_video_views_counters_columns
    columns = {
      last_30_days_main_video_views: 0,
      last_30_days_extra_video_views: 0,
      last_30_days_dev_video_views: 0,
      last_30_days_invalid_video_views: 0,
      last_30_days_embed_video_views: 0,
      last_30_days_billable_video_views_array: []
    }

    from = 30.days.ago.midnight
    to   = 1.day.ago.end_of_day
    last_30_days_stats = site.day_stats.between(d: from..to).entries

    while from <= to
      if last_30_days_stats.first.try(:[], 'd') == from
        s = last_30_days_stats.shift
        columns[:last_30_days_main_video_views]    += s.vv['m'].to_i
        columns[:last_30_days_extra_video_views]   += s.vv['e'].to_i
        columns[:last_30_days_dev_video_views]     += s.vv['d'].to_i
        columns[:last_30_days_invalid_video_views] += s.vv['i'].to_i
        columns[:last_30_days_embed_video_views]   += s.vv['em'].to_i
        columns[:last_30_days_billable_video_views_array] << (s.vv['m'].to_i + s.vv['e'].to_i + s.vv['em'].to_i)
      else
        columns[:last_30_days_billable_video_views_array] << 0
      end
      from += 1.day
    end
    # Handle serialiazed array
    columns[:last_30_days_billable_video_views_array] = columns[:last_30_days_billable_video_views_array].to_yaml
    columns
  end

end
