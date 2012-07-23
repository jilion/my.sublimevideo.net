module SiteModules::UsageMonitoring
  extend ActiveSupport::Concern

  module ClassMethods

    def monitor_sites_usages
      Site.in_paid_plan.where(first_plan_upgrade_required_alert_sent_at: nil).each do |site|
        if site.current_monthly_billable_usages.sum > site.plan.video_views
          if site.days_since(site.first_paid_plan_started_at) >= 20 && site.percentage_of_days_over_daily_limit(60) > 0.5
            # site.touch(:first_plan_upgrade_required_alert_sent_at)
            # UsageMonitoringMailer.delay.plan_upgrade_required(site.id)
          elsif site.overusage_notification_sent_at.nil? || site.overusage_notification_sent_at < site.plan_month_cycle_started_at
            site.touch(:overusage_notification_sent_at)
            UsageMonitoringMailer.delay.plan_overused(site.id)
          end
        end
      end

      # Sent daily "plan upgrade required" alert
      # Site.in_paid_plan.where { first_plan_upgrade_required_alert_sent_at != nil }.each do |site|
      #   UsageMonitoringMailer.delay.plan_upgrade_required(site.id)
      # end
    end

  end

end
