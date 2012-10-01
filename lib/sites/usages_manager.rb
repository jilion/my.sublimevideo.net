require_dependency 'sites/usage_manager'

module Sites
  class UsagesManager

    class << self

      def update_last_30_days_counters_for_not_archived_sites
        Site.not_archived.find_each(batch_size: 100) do |site|
          usage_manager = UsageManager.new(site)
          usage_manager.update_last_30_days_video_tags_counters
          usage_manager.update_last_30_days_video_views_counters
        end
      end

      def set_first_billable_plays_at_for_not_archived_sites
        Site.not_archived.where(first_billable_plays_at: nil).find_each(batch_size: 100) do |site|
          UsageManager.new(site).set_first_billable_plays_at
        end
      end

    end

  end
end
