module SiteModules::Usage
  extend ActiveSupport::Concern

  module InstanceMethods
    extend ActiveSupport::Memoizable

    def update_last_30_days_counters
      self.last_30_days_main_video_views    = 0
      self.last_30_days_extra_video_views   = 0
      self.last_30_days_dev_video_views     = 0
      self.last_30_days_invalid_video_views = 0
      self.last_30_days_embed_video_views   = 0
      self.last_30_days_billable_video_views_array = []

      from = 30.days.ago.midnight
      to   = 1.day.ago.midnight
      last_30_days_stats = stats.d_between(from, to).entries

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
      self.save_skip_pwd
    end

    def billable_usages(options = {})
      monthly_usages = stats.d_between(options[:from], options[:to]).map(&:billable_vv)
      if options[:drop_first_zeros]
        monthly_usages.drop_while { |usage| usage == 0 }
      else
        monthly_usages
      end
    end

    def last_30_days_billable_video_views
      last_30_days_main_video_views.to_i + last_30_days_extra_video_views.to_i + last_30_days_embed_video_views.to_i
    end
    memoize :last_30_days_billable_video_views

    def last_30_days_billable_usages
      billable_usages(from: 30.days.ago.midnight, to: 1.day.ago.midnight, drop_first_zeros: true)
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
        over_limit_days = stats.d_between(last_days.days.ago.utc.midnight, 1.day.ago.midnight).to_a.count { |su| su.billable_vv > (plan.video_views / 30.0) }

        [(over_limit_days / last_days.to_f).round(2), 1].min
      else
        0
      end
    end

  end

end
