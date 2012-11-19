module SiteModules::Usage
  extend ActiveSupport::Concern

  module ClassMethods
    def update_last_30_days_counters_for_not_archived_sites
      not_archived.find_each(batch_size: 100) do |site|
        site.update_last_30_days_video_tags_counters
        site.update_last_30_days_video_views_counters
      end
    end

    def set_first_billable_plays_at_for_not_archived_sites
      not_archived.where(first_billable_plays_at: nil).find_each(batch_size: 100) do |site|
        site.set_first_billable_plays_at
      end
    end
  end

  def update_last_30_days_video_tags_counters
    self.update_column(:last_30_days_video_tags, self.video_tags.last_30_days_active.count)
  end

  def update_last_30_days_video_views_counters
    self.last_30_days_main_video_views    = 0
    self.last_30_days_extra_video_views   = 0
    self.last_30_days_dev_video_views     = 0
    self.last_30_days_invalid_video_views = 0
    self.last_30_days_embed_video_views   = 0
    self.last_30_days_billable_video_views_array = []

    from = 30.days.ago.midnight
    to   = 1.day.ago.end_of_day
    last_30_days_stats = day_stats.between(d: from..to).entries

    while from <= to
      if last_30_days_stats.first.try(:[], 'd') == from
        s = last_30_days_stats.shift
        self.last_30_days_main_video_views    += s.vv['m'].to_i
        self.last_30_days_extra_video_views   += s.vv['e'].to_i
        self.last_30_days_dev_video_views     += s.vv['d'].to_i
        self.last_30_days_invalid_video_views += s.vv['i'].to_i
        self.last_30_days_embed_video_views   += s.vv['em'].to_i
        self.last_30_days_billable_video_views_array << (s.vv['m'].to_i + s.vv['e'].to_i + s.vv['em'].to_i)
      else
        self.last_30_days_billable_video_views_array << 0
      end
      from += 1.day
    end
    self.skip_password(:save!, validate: false)
  end

  def set_first_billable_plays_at
    stat = day_stats.order_by(d: 1).detect { |s| s.billable_vv >= 10 } ||
           usages.order_by([:day, :asc]).detect { |s| s.billable_player_hits >= 10 }

    self.update_column(:first_billable_plays_at, stat.respond_to?(:d) ? stat.d : stat.day) if stat
  end

  def billable_usages(options = {})
    monthly_usages = day_stats.between(d: options[:from]..options[:to]).map(&:billable_vv)
    if options[:drop_first_zeros]
      monthly_usages.drop_while { |usage| usage == 0 }
    else
      monthly_usages
    end
  end

  def last_30_days_billable_video_views
    @last_30_days_billable_video_views ||= last_30_days_main_video_views.to_i + last_30_days_extra_video_views.to_i + last_30_days_embed_video_views.to_i
  end

  def last_30_days_billable_usages
    @last_30_days_billable_usages ||= billable_usages(from: 30.days.ago.midnight, to: 1.day.ago.end_of_day, drop_first_zeros: true)
  end

  def current_monthly_billable_usages
    @current_monthly_billable_usages ||= billable_usages(from: Time.now.utc.beginning_of_month, to: Time.now.utc.end_of_month)
  end

  def unmemoize_all_usages
    @last_30_days_billable_video_views = nil
    @last_30_days_billable_usages      = nil
    @current_monthly_billable_usages   = nil
  end

end
