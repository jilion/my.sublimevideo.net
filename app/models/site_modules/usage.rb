module SiteModules::Usage
  extend ActiveSupport::Concern

  module InstanceMethods
    extend ActiveSupport::Memoizable

    def update_last_30_days_counters
      self.last_30_days_main_video_views  = 0
      self.last_30_days_extra_video_views = 0
      self.last_30_days_dev_video_views   = 0
      usages.between(Time.now.utc.midnight - 30.days, Time.now.utc.midnight).all.each do |usage|
        self.last_30_days_main_video_views  += usage.main_player_hits + usage.main_player_hits_cached
        self.last_30_days_extra_video_views += usage.extra_player_hits + usage.extra_player_hits_cached
        self.last_30_days_dev_video_views   += usage.dev_player_hits + usage.dev_player_hits_cached
      end
      self.save
    end

    def billable_usages(options = {})
      monthly_usages = usages.between(options[:from], options[:to]).asc(:day).map(&:billable_player_hits)
      if options[:drop_first_zeros]
        monthly_usages.drop_while { |usage| usage == 0 }
      else
        monthly_usages
      end
    end

    def last_30_days_billable_usages
      billable_usages(from: (30.days - 1.day).ago.midnight, to: Time.now.utc.end_of_day, drop_first_zeros: true)
    end
    memoize :last_30_days_billable_usages

    def current_monthly_billable_usages
      billable_usages(from: plan_month_cycle_started_at, to: plan_month_cycle_ended_at)
    end
    memoize :current_monthly_billable_usages

    def current_percentage_of_plan_used
      if in_paid_plan?
        percentage = [(current_monthly_billable_usages.sum / plan.video_views.to_f).round(2), 1].min
        percentage == 0.0 && current_monthly_billable_usages.sum > 0 ? 0.01 : percentage
      else
        0
      end
    end

    def percentage_of_days_over_daily_limit(max_days = 60)
      if in_paid_plan?
        last_days       = [days_since(first_paid_plan_started_at), max_days].min
        over_limit_days = usages.between(last_days.days.ago.utc.midnight, Time.now.utc.midnight).to_a.count { |su| su.billable_player_hits > (plan.video_views / 30.0) }

        [(over_limit_days / last_days.to_f).round(2), 1].min
      else
        0
      end
    end

  end

end
