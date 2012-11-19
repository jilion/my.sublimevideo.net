module SiteModules::Usage
  extend ActiveSupport::Concern

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
