module Service
  Usage = Struct.new(:site) do

    class << self

      def set_first_billable_plays_at_for_not_archived_sites
        ::Site.not_archived.where(first_billable_plays_at: nil).find_each(batch_size: 100) do |site|
          new(site).set_first_billable_plays_at
        end
      end

      def update_last_30_days_counters_for_not_archived_sites
        ::Site.not_archived.find_each(batch_size: 100) do |site|
          new(site).update_last_30_days_video_tags_counters.update_last_30_days_video_views_counters
        end
      end

    end

    def set_first_billable_plays_at
      if stat = site.day_stats.order_by(d: 1).detect { |s| s.billable_vv >= 10 }
        site.update_column(:first_billable_plays_at, stat.respond_to?(:d) ? stat.d : stat.day)
      end
    end

    def update_last_30_days_video_tags_counters
      site.update_column(:last_30_days_video_tags, site.video_tags.last_30_days_active.count)

      self
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

      self
    end

  end
end
