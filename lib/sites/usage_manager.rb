module Sites
  class UsageManager < Struct.new(:site)

    def set_first_billable_plays_at
      stat = site.day_stats.order_by(d: 1).detect { |s| s.billable_vv >= 10 } ||
             site.usages.order_by([:day, :asc]).detect { |s| s.billable_player_hits >= 10 }

      site.update_column(:first_billable_plays_at, stat.respond_to?(:d) ? stat.d : stat.day) if stat
    end

    def update_last_30_days_video_tags_counters
      site.update_column(:last_30_days_video_tags, VideoTag.last_30_days_updated_count(site.token))
    end

    def update_last_30_days_video_views_counters
      site.last_30_days_main_video_views    = 0
      site.last_30_days_extra_video_views   = 0
      site.last_30_days_dev_video_views     = 0
      site.last_30_days_invalid_video_views = 0
      site.last_30_days_embed_video_views   = 0
      site.last_30_days_billable_video_views_array = []

      from = 30.days.ago.midnight
      to   = 1.day.ago.end_of_day
      last_30_days_stats = site.day_stats.between(d: from..to).entries

      while from <= to
        if last_30_days_stats.first.try(:[], 'd') == from
          s = last_30_days_stats.shift
          site.last_30_days_main_video_views    += s.vv['m'].to_i
          site.last_30_days_extra_video_views   += s.vv['e'].to_i
          site.last_30_days_dev_video_views     += s.vv['d'].to_i
          site.last_30_days_invalid_video_views += s.vv['i'].to_i
          site.last_30_days_embed_video_views   += s.vv['em'].to_i
          site.last_30_days_billable_video_views_array << (s.vv['m'].to_i + s.vv['e'].to_i + s.vv['em'].to_i)
        else
          site.last_30_days_billable_video_views_array << 0
        end
        from += 1.day
      end
      site.save!
    end

  end
end
