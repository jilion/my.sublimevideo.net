module SiteModules::UsageMonitoring
  extend ActiveSupport::Concern

  module ClassMethods

    def monitor_sites_usages
      Site.paid_plan.where(first_plan_upgrade_required_alert_sent_at: nil).each do |site|
        if site.current_monthly_billable_usages.sum > site.plan.video_views
          if site.days_since(site.first_paid_plan_started_at) >= 20 && site.percentage_of_days_over_daily_limit(60) > 0.5
            # site.touch(:first_plan_upgrade_required_alert_sent_at)
            # My::UsageMonitoringMailer.plan_upgrade_required(site).deliver!
          elsif site.overusage_notification_sent_at.nil? || site.overusage_notification_sent_at < site.plan_month_cycle_started_at
            site.touch(:overusage_notification_sent_at)
            My::UsageMonitoringMailer.plan_overused(site).deliver!
          end
        end
      end

      # Sent daily "plan upgrade required" alert
      # Site.paid_plan.where { first_plan_upgrade_required_alert_sent_at != nil }.each do |site|
      #   My::UsageMonitoringMailer.plan_upgrade_required(site).deliver!
      # end
    end

  end

end

# == Schema Information
#
# Table name: sites
#
#  overusage_notification_sent_at :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#
